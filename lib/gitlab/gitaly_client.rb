require 'base64'

require 'gitaly'
require 'grpc/health/v1/health_pb'
require 'grpc/health/v1/health_services_pb'

module Gitlab
  module GitalyClient
    include Gitlab::Metrics::Methods
    module MigrationStatus
      DISABLED = 1
      OPT_IN = 2
      OPT_OUT = 3
    end

    class TooManyInvocationsError < StandardError
      attr_reader :call_site, :invocation_count, :max_call_stack

      def initialize(call_site, invocation_count, max_call_stack, most_invoked_stack)
        @call_site = call_site
        @invocation_count = invocation_count
        @max_call_stack = max_call_stack
        stacks = most_invoked_stack.join('\n') if most_invoked_stack

        msg = "GitalyClient##{call_site} called #{invocation_count} times from single request. Potential n+1?"
        msg << "\nThe following call site called into Gitaly #{max_call_stack} times:\n#{stacks}\n" if stacks

        super(msg)
      end
    end

    SERVER_VERSION_FILE = 'GITALY_SERVER_VERSION'.freeze
    MAXIMUM_GITALY_CALLS = 35
    CLIENT_NAME = (Sidekiq.server? ? 'gitlab-sidekiq' : 'gitlab-web').freeze

    MUTEX = Mutex.new

    class << self
      attr_accessor :query_time
    end

    self.query_time = 0

    define_histogram :gitaly_migrate_call_duration_seconds do
      docstring "Gitaly migration call execution timings"
      base_labels gitaly_enabled: nil, feature: nil
    end

    define_histogram :gitaly_controller_action_duration_seconds do
      docstring "Gitaly endpoint histogram by controller and action combination"
      base_labels Gitlab::Metrics::Transaction::BASE_LABELS.merge(gitaly_service: nil, rpc: nil)
    end

    def self.stub(name, storage)
      MUTEX.synchronize do
        @stubs ||= {}
        @stubs[storage] ||= {}
        @stubs[storage][name] ||= begin
          klass = stub_class(name)
          addr = stub_address(storage)
          klass.new(addr, :this_channel_is_insecure)
        end
      end
    end

    def self.stub_class(name)
      if name == :health_check
        Grpc::Health::V1::Health::Stub
      else
        Gitaly.const_get(name.to_s.camelcase.to_sym).const_get(:Stub)
      end
    end

    def self.stub_address(storage)
      addr = address(storage)
      addr = addr.sub(%r{^tcp://}, '') if URI(addr).scheme == 'tcp'
      addr
    end

    def self.clear_stubs!
      MUTEX.synchronize do
        @stubs = nil
      end
    end

    def self.random_storage
      Gitlab.config.repositories.storages.keys.sample
    end

    def self.address(storage)
      params = Gitlab.config.repositories.storages[storage]
      raise "storage not found: #{storage.inspect}" if params.nil?

      address = params['gitaly_address']
      unless address.present?
        raise "storage #{storage.inspect} is missing a gitaly_address"
      end

      unless URI(address).scheme.in?(%w(tcp unix))
        raise "Unsupported Gitaly address: #{address.inspect} does not use URL scheme 'tcp' or 'unix'"
      end

      address
    end

    def self.address_metadata(storage)
      Base64.strict_encode64(JSON.dump({ storage => { 'address' => address(storage), 'token' => token(storage) } }))
    end

    # All Gitaly RPC call sites should use GitalyClient.call. This method
    # makes sure that per-request authentication headers are set.
    #
    # This method optionally takes a block which receives the keyword
    # arguments hash 'kwargs' that will be passed to gRPC. This allows the
    # caller to modify or augment the keyword arguments. The block must
    # return a hash.
    #
    # For example:
    #
    # GitalyClient.call(storage, service, rpc, request) do |kwargs|
    #   kwargs.merge(deadline: Time.now + 10)
    # end
    #
    def self.call(storage, service, rpc, request, remote_storage: nil, timeout: nil)
      start = Gitlab::Metrics::System.monotonic_time
      request_hash = request.is_a?(Google::Protobuf::MessageExts) ? request.to_h : {}
      @current_call_id ||= SecureRandom.uuid

      enforce_gitaly_request_limits(:call)

      kwargs = request_kwargs(storage, timeout, remote_storage: remote_storage)
      kwargs = yield(kwargs) if block_given?

      stub(service, storage).__send__(rpc, request, kwargs) # rubocop:disable GitlabSecurity/PublicSend
    rescue GRPC::Unavailable => ex
      handle_grpc_unavailable!(ex)
    ensure
      duration = Gitlab::Metrics::System.monotonic_time - start

      # Keep track, seperately, for the performance bar
      self.query_time += duration
      gitaly_controller_action_duration_seconds.observe(
        current_transaction_labels.merge(gitaly_service: service.to_s, rpc: rpc.to_s),
        duration)

      add_call_details(id: @current_call_id, feature: service, duration: duration, request: request_hash)

      @current_call_id = nil
    end

    def self.handle_grpc_unavailable!(ex)
      status = ex.to_status
      raise ex unless status.details == 'Endpoint read failed'

      # There is a bug in grpc 1.8.x that causes a client process to get stuck
      # always raising '14:Endpoint read failed'. The only thing that we can
      # do to recover is to restart the process.
      #
      # See https://gitlab.com/gitlab-org/gitaly/issues/1029

      if Sidekiq.server?
        raise Gitlab::SidekiqMiddleware::Shutdown::WantShutdown.new(ex.to_s)
      else
        # SIGQUIT requests a Unicorn worker to shut down gracefully after the current request.
        Process.kill('QUIT', Process.pid)
      end

      raise ex
    end
    private_class_method :handle_grpc_unavailable!

    def self.current_transaction_labels
      Gitlab::Metrics::Transaction.current&.labels || {}
    end
    private_class_method :current_transaction_labels

    def self.request_kwargs(storage, timeout, remote_storage: nil)
      encoded_token = Base64.strict_encode64(token(storage).to_s)
      metadata = {
        'authorization' => "Bearer #{encoded_token}",
        'client_name' => CLIENT_NAME
      }

      feature_stack = Thread.current[:gitaly_feature_stack]
      feature = feature_stack && feature_stack[0]
      metadata['call_site'] = feature.to_s if feature
      metadata['gitaly-servers'] = address_metadata(remote_storage) if remote_storage

      result = { metadata: metadata }

      # nil timeout indicates that we should use the default
      timeout = default_timeout if timeout.nil?

      return result unless timeout > 0

      # Do not use `Time.now` for deadline calculation, since it
      # will be affected by Timecop in some tests, but grpc's c-core
      # uses system time instead of timecop's time, so tests will fail
      # `Time.at(Process.clock_gettime(Process::CLOCK_REALTIME))` will
      # circumvent timecop
      deadline = Time.at(Process.clock_gettime(Process::CLOCK_REALTIME)) + timeout
      result[:deadline] = deadline

      result
    end

    def self.token(storage)
      params = Gitlab.config.repositories.storages[storage]
      raise "storage not found: #{storage.inspect}" if params.nil?

      params['gitaly_token'].presence || Gitlab.config.gitaly['token']
    end

    # Evaluates whether a feature toggle is on or off
    def self.feature_enabled?(feature_name, status: MigrationStatus::OPT_IN)
      # Disabled features are always off!
      return false if status == MigrationStatus::DISABLED

      feature = Feature.get("gitaly_#{feature_name}")

      # If the feature has been set, always evaluate
      if Feature.persisted?(feature)
        if feature.percentage_of_time_value > 0
          # Probabilistically enable this feature
          return Random.rand() * 100 < feature.percentage_of_time_value
        end

        return feature.enabled?
      end

      # If the feature has not been set, the default depends
      # on it's status
      case status
      when MigrationStatus::OPT_OUT
        true
      when MigrationStatus::OPT_IN
        opt_into_all_features?
      else
        false
      end
    end

    # opt_into_all_features? returns true when the current environment
    # is one in which we opt into features automatically
    def self.opt_into_all_features?
      Rails.env.development? || ENV["GITALY_FEATURE_DEFAULT_ON"] == "1"
    end
    private_class_method :opt_into_all_features?

    def self.migrate(feature, status: MigrationStatus::OPT_IN)
      # Enforce limits at both the `migrate` and `call` sites to ensure that
      # problems are not hidden by a feature being disabled
      enforce_gitaly_request_limits(:migrate)

      is_enabled  = feature_enabled?(feature, status: status)
      metric_name = feature.to_s
      metric_name += "_gitaly" if is_enabled

      Gitlab::Metrics.measure(metric_name) do
        # Some migrate calls wrap other migrate calls
        allow_n_plus_1_calls do
          feature_stack = Thread.current[:gitaly_feature_stack] ||= []
          feature_stack.unshift(feature)
          begin
            start = Gitlab::Metrics::System.monotonic_time
            @current_call_id = SecureRandom.uuid
            call_details = { id: @current_call_id }
            yield is_enabled
          ensure
            total_time = Gitlab::Metrics::System.monotonic_time - start
            gitaly_migrate_call_duration_seconds.observe({ gitaly_enabled: is_enabled, feature: feature }, total_time)
            feature_stack.shift
            Thread.current[:gitaly_feature_stack] = nil if feature_stack.empty?

            add_call_details(call_details.merge(feature: feature, duration: total_time))
          end
        end
      end
    end

    # Ensures that Gitaly is not being abuse through n+1 misuse etc
    def self.enforce_gitaly_request_limits(call_site)
      # Only count limits in request-response environments (not sidekiq for example)
      return unless RequestStore.active?

      # This is this actual number of times this call was made. Used for information purposes only
      actual_call_count = increment_call_count("gitaly_#{call_site}_actual")

      # Do no enforce limits in production
      return if Rails.env.production? || ENV["GITALY_DISABLE_REQUEST_LIMITS"]

      # Check if this call is nested within a allow_n_plus_1_calls
      # block and skip check if it is
      return if get_call_count(:gitaly_call_count_exception_block_depth) > 0

      # This is the count of calls outside of a `allow_n_plus_1_calls` block
      # It is used for enforcement but not statistics
      permitted_call_count = increment_call_count("gitaly_#{call_site}_permitted")

      count_stack

      return if permitted_call_count <= MAXIMUM_GITALY_CALLS

      raise TooManyInvocationsError.new(call_site, actual_call_count, max_call_count, max_stacks)
    end

    def self.allow_n_plus_1_calls
      return yield unless RequestStore.active?

      begin
        increment_call_count(:gitaly_call_count_exception_block_depth)
        yield
      ensure
        decrement_call_count(:gitaly_call_count_exception_block_depth)
      end
    end

    def self.get_call_count(key)
      RequestStore.store[key] || 0
    end
    private_class_method :get_call_count

    def self.increment_call_count(key)
      RequestStore.store[key] ||= 0
      RequestStore.store[key] += 1
    end
    private_class_method :increment_call_count

    def self.decrement_call_count(key)
      RequestStore.store[key] -= 1
    end
    private_class_method :decrement_call_count

    # Returns an estimate of the number of Gitaly calls made for this
    # request
    def self.get_request_count
      return 0 unless RequestStore.active?

      gitaly_migrate_count = get_call_count("gitaly_migrate_actual")
      gitaly_call_count = get_call_count("gitaly_call_actual")

      # Using the maximum of migrate and call_count will provide an
      # indicator of how many Gitaly calls will be made, even
      # before a feature is enabled. This provides us with a single
      # metric, but not an exact number, but this tradeoff is acceptable
      if gitaly_migrate_count > gitaly_call_count
        gitaly_migrate_count
      else
        gitaly_call_count
      end
    end

    def self.reset_counts
      return unless RequestStore.active?

      %w[migrate call].each do |call_site|
        RequestStore.store["gitaly_#{call_site}_actual"] = 0
        RequestStore.store["gitaly_#{call_site}_permitted"] = 0
      end
    end

    def self.add_call_details(details)
      id = details.delete(:id)

      return unless id && RequestStore.active? && RequestStore.store[:peek_enabled]

      RequestStore.store['gitaly_call_details'] ||= {}
      RequestStore.store['gitaly_call_details'][id] ||= {}
      RequestStore.store['gitaly_call_details'][id].merge!(details)
    end

    def self.list_call_details
      return {} unless RequestStore.active? && RequestStore.store[:peek_enabled]

      RequestStore.store['gitaly_call_details'] || {}
    end

    def self.expected_server_version
      path = Rails.root.join(SERVER_VERSION_FILE)
      path.read.chomp
    end

    def self.timestamp(t)
      Google::Protobuf::Timestamp.new(seconds: t.to_i)
    end

    # The default timeout on all Gitaly calls
    def self.default_timeout
      return 0 if Sidekiq.server?

      timeout(:gitaly_timeout_default)
    end

    def self.fast_timeout
      timeout(:gitaly_timeout_fast)
    end

    def self.medium_timeout
      timeout(:gitaly_timeout_medium)
    end

    def self.timeout(timeout_name)
      Gitlab::CurrentSettings.current_application_settings[timeout_name]
    end
    private_class_method :timeout

    # Count a stack. Used for n+1 detection
    def self.count_stack
      return unless RequestStore.active?

      stack_string = caller.drop(1).join("\n")

      RequestStore.store[:stack_counter] ||= Hash.new

      count = RequestStore.store[:stack_counter][stack_string] || 0
      RequestStore.store[:stack_counter][stack_string] = count + 1
    end
    private_class_method :count_stack

    # Returns a count for the stack which called Gitaly the most times. Used for n+1 detection
    def self.max_call_count
      return 0 unless RequestStore.active?

      stack_counter = RequestStore.store[:stack_counter]
      return 0 unless stack_counter

      stack_counter.values.max
    end
    private_class_method :max_call_count

    # Returns the stacks that calls Gitaly the most times. Used for n+1 detection
    def self.max_stacks
      return nil unless RequestStore.active?

      stack_counter = RequestStore.store[:stack_counter]
      return nil unless stack_counter

      max = max_call_count
      return nil if max.zero?

      stack_counter.select { |_, v| v == max }.keys
    end
    private_class_method :max_stacks
  end
end
