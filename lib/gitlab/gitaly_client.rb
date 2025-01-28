# frozen_string_literal: true

require 'base64'

require 'gitaly'
require 'grpc/health/v1/health_pb'
require 'grpc/health/v1/health_services_pb'

module Gitlab
  module GitalyClient
    class TooManyInvocationsError < StandardError
      attr_reader :call_site, :invocation_count, :max_call_stack

      def initialize(call_site, invocation_count, max_call_stack, most_invoked_stack)
        @call_site = call_site
        @invocation_count = invocation_count
        @max_call_stack = max_call_stack
        stacks = most_invoked_stack.join('\n') if most_invoked_stack

        msg = "GitalyClient##{call_site} called #{invocation_count} times from single request. Potential n+1?"
        msg = "#{msg}\nThe following call site called into Gitaly #{max_call_stack} times:\n#{stacks}\n" if stacks

        super(msg)
      end
    end

    SERVER_VERSION_FILE = 'GITALY_SERVER_VERSION'
    MAXIMUM_GITALY_CALLS = 30
    CLIENT_NAME = (Gitlab::Runtime.sidekiq? ? 'gitlab-sidekiq' : 'gitlab-web').freeze
    GITALY_METADATA_FILENAME = '.gitaly-metadata'

    MUTEX = Mutex.new

    def self.stub(name, storage)
      MUTEX.synchronize do
        @stubs ||= {}
        @stubs[storage] ||= {}
        @stubs[storage][name] ||= begin
          klass = stub_class(name)
          channel = create_channel(storage)
          klass.new(channel.target, nil, interceptors: interceptors, channel_override: channel)
        end
      end
    end

    def self.interceptors
      return [] unless Labkit::Tracing.enabled?

      [Labkit::Tracing::GRPC::ClientInterceptor.instance]
    end
    private_class_method :interceptors

    def self.channel_args
      {
        # These keepalive values match the go Gitaly client
        # https://gitlab.com/gitlab-org/gitaly/-/blob/bf9f52bc/client/dial.go#L78
        'grpc.keepalive_time_ms': 20000,
        'grpc.keepalive_permit_without_calls': 1,
        # Service config is a mechanism for grpc to control the behavior of gRPC client. It defines the client-side
        # balancing strategy and retry policy. The config receives a raw JSON string. The format is defined here:
        # https://github.com/grpc/grpc-proto/blob/master/grpc/service_config/service_config.proto
        'grpc.service_config': {
          # By default, gRPC uses pick_first strategy. This strategy establishes one single connection to the first
          # target returned by the name resolver. We would like to use round_robin load-balancing strategy so that
          # grpc creates multiple subchannels to all targets retrurned by the resolver. Requests are distributed to
          # those subchannels in a round-robin fashion.
          # More about client-side load-balancing: https://gitlab.com/groups/gitlab-org/-/epics/8971#note_1207008162
          loadBalancingConfig: [{ round_robin: {} }],
          # Enable retries for read-only RPCs. With this setting the client to will resend requests that fail with
          # the following conditions:
          #   1. An `UNAVAILABLE` status code was received.
          #   2. No response-headers were received from the server.
          # This allows the client to handle momentary service interruptions without user-facing errors. gRPC's
          # automatic 'transparent retries' may also be sent.
          # For more information please visit https://github.com/grpc/proposal/blob/master/A6-client-retries.md
          methodConfig: [
            {
              # Gitaly sets an `op_type` `MethodOption` on RPCs to note if it mutates a repository. We cannot
              # programatically detect read-only RPCs, i.e. those safe to retry, because Ruby's protobuf
              # implementation does not provide access to `MethodOptions`. That feature is being tracked under
              # https://github.com/protocolbuffers/protobuf/issues/1198. When that is complete we can replace this
              # table.
              name: [
                { service: 'gitaly.BlobService', method:   'GetBlob' },
                { service: 'gitaly.BlobService', method:   'GetBlobs' },
                { service: 'gitaly.BlobService', method:   'GetLFSPointers' },
                { service: 'gitaly.BlobService', method:   'GetAllLFSPointers' },
                { service: 'gitaly.BlobService', method:   'ListAllBlobs' },
                { service: 'gitaly.BlobService', method:   'ListAllLFSPointers' },
                { service: 'gitaly.BlobService', method:   'ListBlobs' },
                { service: 'gitaly.BlobService', method:   'ListLFSPointers' },
                { service: 'gitaly.CommitService', method: 'CheckObjectsExist' },
                { service: 'gitaly.CommitService', method: 'CommitIsAncestor' },
                { service: 'gitaly.CommitService', method: 'CommitLanguages' },
                { service: 'gitaly.CommitService', method: 'CommitStats' },
                { service: 'gitaly.CommitService', method: 'CommitsByMessage' },
                { service: 'gitaly.CommitService', method: 'CountCommits' },
                { service: 'gitaly.CommitService', method: 'CountDivergingCommits' },
                { service: 'gitaly.CommitService', method: 'FilterShasWithSignatures' },
                { service: 'gitaly.CommitService', method: 'FindAllCommits' },
                { service: 'gitaly.CommitService', method: 'FindCommit' },
                { service: 'gitaly.CommitService', method: 'FindCommits' },
                { service: 'gitaly.CommitService', method: 'GetCommitMessages' },
                { service: 'gitaly.CommitService', method: 'GetCommitSignatures' },
                { service: 'gitaly.CommitService', method: 'GetTreeEntries' },
                { service: 'gitaly.CommitService', method: 'LastCommitForPath' },
                { service: 'gitaly.CommitService', method: 'ListAllCommits' },
                { service: 'gitaly.CommitService', method: 'ListCommits' },
                { service: 'gitaly.CommitService', method: 'ListCommitsByOid' },
                { service: 'gitaly.CommitService', method: 'ListCommitsByRefName' },
                { service: 'gitaly.CommitService', method: 'ListFiles' },
                { service: 'gitaly.CommitService', method: 'ListLastCommitsForTree' },
                { service: 'gitaly.CommitService', method: 'RawBlame' },
                { service: 'gitaly.CommitService', method: 'TreeEntry' },
                { service: 'gitaly.ConflictsService', method: 'ListConflictFiles' },
                { service: 'gitaly.DiffService', method: 'CommitDelta' },
                { service: 'gitaly.DiffService', method: 'CommitDiff' },
                { service: 'gitaly.DiffService', method: 'DiffStats' },
                { service: 'gitaly.DiffService', method: 'FindChangedPaths' },
                { service: 'gitaly.DiffService', method: 'GetPatchID' },
                { service: 'gitaly.DiffService', method: 'RawDiff' },
                { service: 'gitaly.DiffService', method: 'RawPatch' },
                { service: 'gitaly.ObjectPoolService', method: 'GetObjectPool' },
                { service: 'gitaly.RefService', method: 'FindAllBranches' },
                { service: 'gitaly.RefService', method: 'FindAllRemoteBranches' },
                { service: 'gitaly.RefService', method: 'FindAllTags' },
                { service: 'gitaly.RefService', method: 'FindBranch' },
                { service: 'gitaly.RefService', method: 'FindDefaultBranchName' },
                { service: 'gitaly.RefService', method: 'FindLocalBranches' },
                { service: 'gitaly.RefService', method: 'FindRefsByOID' },
                { service: 'gitaly.RefService', method: 'FindTag' },
                { service: 'gitaly.RefService', method: 'GetTagMessages' },
                { service: 'gitaly.RefService', method: 'GetTagSignatures' },
                { service: 'gitaly.RefService', method: 'ListBranchNamesContainingCommit' },
                { service: 'gitaly.RefService', method: 'ListRefs' },
                { service: 'gitaly.RefService', method: 'ListTagNamesContainingCommit' },
                { service: 'gitaly.RefService', method: 'RefExists' },
                { service: 'gitaly.RemoteService', method: 'FindRemoteRepository' },
                { service: 'gitaly.RemoteService', method: 'FindRemoteRootRef' },
                { service: 'gitaly.RemoteService', method: 'UpdateRemoteMirror' },
                { service: 'gitaly.RepositoryService', method: 'BackupCustomHooks' },
                { service: 'gitaly.RepositoryService', method: 'BackupRepository' },
                { service: 'gitaly.RepositoryService', method: 'CalculateChecksum' },
                { service: 'gitaly.RepositoryService', method: 'CreateBundle' },
                { service: 'gitaly.RepositoryService', method: 'Fsck' },
                { service: 'gitaly.RepositoryService', method: 'FindLicense' },
                { service: 'gitaly.RepositoryService', method: 'FindMergeBase' },
                { service: 'gitaly.RepositoryService', method: 'FullPath' },
                { service: 'gitaly.RepositoryService', method: 'HasLocalBranches' },
                { service: 'gitaly.RepositoryService', method: 'GetArchive' },
                { service: 'gitaly.RepositoryService', method: 'GetConfig' },
                { service: 'gitaly.RepositoryService', method: 'GetCustomHooks' },
                { service: 'gitaly.RepositoryService', method: 'GetFileAttributes' },
                { service: 'gitaly.RepositoryService', method: 'GetInfoAttributes' },
                { service: 'gitaly.RepositoryService', method: 'GetObject' },
                { service: 'gitaly.RepositoryService', method: 'GetObjectDirectorySize' },
                { service: 'gitaly.RepositoryService', method: 'GetRawChanges' },
                { service: 'gitaly.RepositoryService', method: 'GetSnapshot' },
                { service: 'gitaly.RepositoryService', method: 'ObjectSize' },
                { service: 'gitaly.RepositoryService', method: 'ObjectFormat' },
                { service: 'gitaly.RepositoryService', method: 'RepositoryExists' },
                { service: 'gitaly.RepositoryService', method: 'RepositoryInfo' },
                { service: 'gitaly.RepositoryService', method: 'RepositorySize' },
                { service: 'gitaly.RepositoryService', method: 'SearchFilesByContent' },
                { service: 'gitaly.RepositoryService', method: 'SearchFilesByName' },
                { service: 'gitaly.ServerService', method: 'DiskStatistics' },
                { service: 'gitaly.ServerService', method: 'ReadinessCheck' },
                { service: 'gitaly.ServerService', method: 'ServerInfo' },
                { service: 'gitaly.ServerService', method: 'ServerSignature' },
                { service: 'grpc.health.v1.Health', method: 'Check' }
              ],
              retryPolicy: {
                maxAttempts: 4, # Initial request, plus up to three retries.
                initialBackoff: '0.4s',
                maxBackoff: '1.4s',
                backoffMultiplier: 2, # Maximum retry duration is 2400ms.
                retryableStatusCodes: ['UNAVAILABLE']
              }
            }
          ]
        }.to_json
      }
    end
    private_class_method :channel_args

    def self.stub_creds(storage)
      if URI(address(storage)).scheme == 'tls'
        GRPC::Core::ChannelCredentials.new ::Gitlab::X509::Certificate.ca_certs_bundle
      else
        :this_channel_is_insecure
      end
    end

    def self.stub_class(name)
      if name == :health_check
        Grpc::Health::V1::Health::Stub
      else
        Gitaly.const_get(name.to_s.camelcase.to_sym, false).const_get(:Stub, false)
      end
    end

    def self.stub_address(storage)
      address(storage).sub(%r{^tcp://|^tls://}, '')
    end

    # Cache gRPC servers by storage. All the client stubs in the same process can share the underlying connection to the
    # same host thanks to HTTP2 framing protocol that gRPC is built on top. This method is not thread-safe. It is
    # intended to be a part of `stub`, method behind a mutex protection.
    def self.create_channel(storage)
      @channels ||= {}
      @channels[storage] ||= GRPC::ClientStub.setup_channel(
        nil, stub_address(storage), stub_creds(storage), channel_args
      )
    end

    def self.clear_stubs!
      MUTEX.synchronize do
        @channels&.each_value(&:close)
        @stubs = nil
        @channels = nil
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

      unless %w[tcp unix tls dns].include?(URI(address).scheme)
        raise "Unsupported Gitaly address: #{address.inspect} does not use URL scheme 'tcp' or 'unix' or 'tls' or 'dns'"
      end

      address
    end

    def self.address_metadata(storage)
      Base64.strict_encode64(Gitlab::Json.dump(storage => connection_data(storage)))
    end

    def self.connection_data(storage)
      { 'address' => address(storage), 'token' => token(storage) }
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
    # The optional remote_storage keyword argument is used to enable
    # inter-gitaly calls. Say you have an RPC that needs to pull data from
    # one repository to another. For example, to fetch a branch from a
    # (non-deduplicated) fork into the fork parent. In that case you would
    # send an RPC call to the Gitaly server hosting the fork parent, and in
    # the request, you would tell that Gitaly server to pull Git data from
    # the fork. How does that Gitaly server connect to the Gitaly server the
    # forked repo lives on? This is the problem `remote_storage:` solves: it
    # adds address and authentication information to the call, as gRPC
    # metadata (under the `gitaly-servers` header). The request would say
    # "pull from repo X on gitaly-2". In the Ruby code you pass
    # `remote_storage: 'gitaly-2'`. And then the metadata would say
    # "gitaly-2 is at network address tcp://10.0.1.2:8075".
    #
    def self.call(storage, service, rpc, request, remote_storage: nil, timeout: default_timeout, gitaly_context: {}, &block)
      Gitlab::GitalyClient::Call.new(storage, service, rpc, request, remote_storage, timeout, gitaly_context: gitaly_context).call(&block)
    end

    def self.execute(storage, service, rpc, request, remote_storage:, timeout:, gitaly_context: {})
      enforce_gitaly_request_limits(:call)
      Gitlab::RequestContext.instance.ensure_deadline_not_exceeded!
      raise_if_concurrent_ruby!

      kwargs = request_kwargs(storage, timeout: timeout.to_f, remote_storage: remote_storage, gitaly_context: gitaly_context)
      kwargs = yield(kwargs) if block_given?

      stub(service, storage).__send__(rpc, request, kwargs) # rubocop:disable GitlabSecurity/PublicSend
    end

    def self.query_time
      query_time = Gitlab::SafeRequestStore[:gitaly_query_time] || 0
      query_time.round(Gitlab::InstrumentationHelper::DURATION_PRECISION)
    end

    def self.add_query_time(duration)
      return unless Gitlab::SafeRequestStore.active?

      Gitlab::SafeRequestStore[:gitaly_query_time] ||= 0
      Gitlab::SafeRequestStore[:gitaly_query_time] += duration
    end

    # For some time related tasks we can't rely on `Time.now` since it will be
    # affected by Timecop in some tests, and the clock of some gitaly-related
    # components (grpc's c-core and gitaly server) use system time instead of
    # timecop's time, so tests will fail.
    # `Time.at(Process.clock_gettime(Process::CLOCK_REALTIME))` will circumvent
    # timecop.
    def self.real_time
      Time.at(Process.clock_gettime(Process::CLOCK_REALTIME))
    end
    private_class_method :real_time

    def self.authorization_token(storage)
      token = token(storage).to_s
      issued_at = real_time.to_i.to_s
      hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('SHA256'), token, issued_at)

      "v2.#{hmac}.#{issued_at}"
    end
    private_class_method :authorization_token

    def self.request_kwargs(storage, timeout:, remote_storage: nil, gitaly_context: {})
      metadata = {
        'authorization' => "Bearer #{authorization_token(storage)}",
        'client_name' => CLIENT_NAME
      }

      relative_path = fetch_relative_path

      ::Gitlab::Auth::Identity.currently_linked do |identity|
        gitaly_context['scoped-user-id'] = identity.scoped_user.id.to_s
      end

      context_data = Gitlab::ApplicationContext.current

      feature_stack = Thread.current[:gitaly_feature_stack]
      feature = feature_stack && feature_stack[0]
      metadata['call_site'] = feature.to_s if feature
      metadata['gitaly-servers'] = address_metadata(remote_storage) if remote_storage
      metadata['x-gitlab-correlation-id'] = Labkit::Correlation::CorrelationId.current_id if Labkit::Correlation::CorrelationId.current_id
      metadata['gitaly-session-id'] = session_id
      metadata['username'] = context_data['meta.user'] if context_data&.fetch('meta.user', nil)
      metadata['user_id'] = context_data['meta.user_id'].to_s if context_data&.fetch('meta.user_id', nil)
      metadata['remote_ip'] = context_data['meta.remote_ip'] if context_data&.fetch('meta.remote_ip', nil)
      metadata['relative-path-bin'] = relative_path if relative_path
      metadata['gitaly-client-context-bin'] = gitaly_context.to_json if gitaly_context.present?

      metadata.merge!(Feature::Gitaly.server_feature_flags(**feature_flag_actors))
      metadata.merge!(route_to_primary)

      deadline_info = request_deadline(timeout)
      metadata.merge!(deadline_info.slice(:deadline_type))

      { metadata: metadata, deadline: deadline_info[:deadline] }
    end

    # The GitLab `internal/allowed/` API sets the :gitlab_git_relative_path
    # variable. This provides the repository relative path which can be used to
    # locate snapshot repositories in Gitaly which act as a quarantine repository
    # until a transaction is committed.
    def self.fetch_relative_path
      return unless Gitlab::SafeRequestStore.active?
      return if Gitlab::SafeRequestStore[:gitlab_git_relative_path].blank?

      Gitlab::SafeRequestStore.fetch(:gitlab_git_relative_path)
    end

    # Gitlab::Git::HookEnv will set the :gitlab_git_env variable in case we're
    # running in the context of a Gitaly hook call, which may make use of
    # quarantined object directories. We thus need to pass along the path of
    # the quarantined object directory to Gitaly, otherwise it won't be able to
    # find these quarantined objects. Given that the quarantine directory is
    # generated with a random name, they'll have different names when multiple
    # Gitaly nodes take part in a single transaction. As a result, we are
    # forced to route all requests to the primary node which has injected the
    # quarantine object directory to us.
    def self.route_to_primary
      return {} unless Gitlab::SafeRequestStore.active?

      return {} if Gitlab::SafeRequestStore[:gitlab_git_env].blank?

      { 'gitaly-route-repository-accessor-policy' => 'primary-only' }
    end
    private_class_method :route_to_primary

    def self.request_deadline(timeout)
      # timeout being 0 means the request is allowed to run indefinitely.
      # We can't allow that inside a request, but this won't count towards Gitaly
      # error budgets
      regular_deadline = real_time.to_i + timeout if timeout > 0

      return { deadline: regular_deadline } if Sidekiq.server?
      return { deadline: regular_deadline } unless Gitlab::RequestContext.instance.request_deadline

      limited_deadline = [regular_deadline, Gitlab::RequestContext.instance.request_deadline].compact.min
      limited = limited_deadline < regular_deadline

      { deadline: limited_deadline, deadline_type: limited ? "limited" : "regular" }
    end
    private_class_method :request_deadline

    def self.session_id
      Gitlab::SafeRequestStore[:gitaly_session_id] ||= SecureRandom.uuid
    end

    def self.token(storage)
      params = Gitlab.config.repositories.storages[storage]
      raise "storage not found: #{storage.inspect}" if params.nil?

      params['gitaly_token'].presence || Gitlab.config.gitaly['token']
    end

    # Ensures that Gitaly is not being abuse through n+1 misuse etc
    def self.enforce_gitaly_request_limits(call_site)
      # Only count limits in request-response environments
      return unless Gitlab::SafeRequestStore.active?

      # This is this actual number of times this call was made. Used for information purposes only
      actual_call_count = increment_call_count("gitaly_#{call_site}_actual")

      return unless enforce_gitaly_request_limits?

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

    def self.enforce_gitaly_request_limits?
      return false if ENV["GITALY_DISABLE_REQUEST_LIMITS"]

      # We typically don't want to enforce request limits in production
      # However, we have some production-like test environments, i.e., ones
      # where `Rails.env.production?` returns `true`. We do want to be able to
      # check if the limit is being exceeded while testing in those environments
      # In that case we can use a feature flag to indicate that we do want to
      # enforce request limits.
      return true if Feature::Gitaly.enabled_for_any?(:gitaly_enforce_requests_limits)

      !Rails.env.production?
    end
    private_class_method :enforce_gitaly_request_limits?

    def self.allow_n_plus_1_calls
      return yield unless Gitlab::SafeRequestStore.active?

      begin
        increment_call_count(:gitaly_call_count_exception_block_depth)
        yield
      ensure
        decrement_call_count(:gitaly_call_count_exception_block_depth)
      end
    end

    # Normally a FindCommit RPC will cache the commit with its SHA
    # instead of a ref name, since it's possible the branch is mutated
    # afterwards. However, for read-only requests that never mutate the
    # branch, this method allows caching of the ref name directly.
    def self.allow_ref_name_caching
      return yield unless Gitlab::SafeRequestStore.active?
      return yield if ref_name_caching_allowed?

      begin
        Gitlab::SafeRequestStore[:allow_ref_name_caching] = true
        yield
      ensure
        Gitlab::SafeRequestStore[:allow_ref_name_caching] = false
      end
    end

    def self.ref_name_caching_allowed?
      Gitlab::SafeRequestStore[:allow_ref_name_caching]
    end

    def self.get_call_count(key)
      Gitlab::SafeRequestStore[key] || 0
    end
    private_class_method :get_call_count

    def self.increment_call_count(key)
      Gitlab::SafeRequestStore[key] ||= 0
      Gitlab::SafeRequestStore[key] += 1
    end
    private_class_method :increment_call_count

    def self.decrement_call_count(key)
      return unless Gitlab::SafeRequestStore[key]

      Gitlab::SafeRequestStore[key] -= 1
    end
    private_class_method :decrement_call_count

    # Returns the of the number of Gitaly calls made for this request
    def self.get_request_count
      get_call_count("gitaly_call_actual")
    end

    def self.reset_counts
      return unless Gitlab::SafeRequestStore.active?

      Gitlab::SafeRequestStore["gitaly_call_actual"] = 0
      Gitlab::SafeRequestStore["gitaly_call_permitted"] = 0
    end

    def self.add_call_details(details)
      Gitlab::SafeRequestStore['gitaly_call_details'] ||= []
      Gitlab::SafeRequestStore['gitaly_call_details'] << details
    end

    def self.list_call_details
      return [] unless Gitlab::PerformanceBar.enabled_for_request?

      Gitlab::SafeRequestStore['gitaly_call_details'] || []
    end

    def self.expected_server_version
      path = Rails.root.join(SERVER_VERSION_FILE)
      path.read.chomp
    end

    def self.timestamp(time)
      Google::Protobuf::Timestamp.new(seconds: time.to_i)
    end

    # The default timeout on all Gitaly calls
    def self.default_timeout
      timeout(:gitaly_timeout_default)
    end

    def self.fast_timeout
      timeout(:gitaly_timeout_fast)
    end

    def self.medium_timeout
      timeout(:gitaly_timeout_medium)
    end

    def self.long_timeout
      if Gitlab::Runtime.puma?
        default_timeout
      else
        6.hours
      end
    end

    def self.filesystem_id(storage)
      Gitlab::GitalyClient::ServerService.new(storage).storage_info&.filesystem_id
    end

    def self.filesystem_disk_available(storage)
      Gitlab::GitalyClient::ServerService.new(storage).storage_disk_statistics&.available
    end

    def self.filesystem_disk_used(storage)
      Gitlab::GitalyClient::ServerService.new(storage).storage_disk_statistics&.used
    end

    def self.timeout(timeout_name)
      Gitlab::CurrentSettings.current_application_settings[timeout_name]
    end
    private_class_method :timeout

    # Count a stack. Used for n+1 detection
    def self.count_stack
      return unless Gitlab::SafeRequestStore.active?

      stack_string = Gitlab::BacktraceCleaner.clean_backtrace(caller).drop(1).join("\n")

      Gitlab::SafeRequestStore[:stack_counter] ||= {}

      count = Gitlab::SafeRequestStore[:stack_counter][stack_string] || 0
      Gitlab::SafeRequestStore[:stack_counter][stack_string] = count + 1
    end
    private_class_method :count_stack

    # Returns a count for the stack which called Gitaly the most times. Used for n+1 detection
    def self.max_call_count
      return 0 unless Gitlab::SafeRequestStore.active?

      stack_counter = Gitlab::SafeRequestStore[:stack_counter]
      return 0 unless stack_counter

      stack_counter.values.max
    end
    private_class_method :max_call_count

    # Returns the stacks that calls Gitaly the most times. Used for n+1 detection
    def self.max_stacks
      return unless Gitlab::SafeRequestStore.active?

      stack_counter = Gitlab::SafeRequestStore[:stack_counter]
      return unless stack_counter

      max = max_call_count
      return if max == 0

      stack_counter.select { |_, v| v == max }.keys
    end
    private_class_method :max_stacks

    def self.decode_detailed_error(err)
      # details could have more than one in theory, but we only have one to worry about for now.
      detailed_error = err.to_rpc_status&.details&.first

      return unless detailed_error.present?

      prefix = %r{type\.googleapis\.com\/gitaly\.(?<error_type>.+)}
      error_type = prefix.match(detailed_error.type_url)[:error_type]

      Gitaly.const_get(error_type, false).decode(detailed_error.value)
    rescue NameError, NoMethodError
      # Error Class might not be known to ruby yet
      nil
    end

    # This method attempts to unwrap a detailed error from a Gitaly RPC error.
    # It first decodes the detailed error using decode_detailed_error. If successful,
    # it tries to extract the unwrapped error by calling the method named by the
    # error attribute on the decoded error object.
    def self.unwrap_detailed_error(err)
      e = decode_detailed_error(err)

      return e if e.nil? || !e.respond_to?(:error) || e.error.nil? || !e.error.respond_to?(:to_s)

      unwrapped_error = e[e.error.to_s]

      unwrapped_error || e
    end

    def self.with_feature_flag_actors(repository: nil, user: nil, project: nil, group: nil, &block)
      feature_flag_actors[:repository] = repository
      feature_flag_actors[:user] = user
      feature_flag_actors[:project] = project
      feature_flag_actors[:group] = group

      yield
    ensure
      feature_flag_actors.clear
    end

    def self.feature_flag_actors
      if Gitlab::SafeRequestStore.active?
        Gitlab::SafeRequestStore[:gitaly_feature_flag_actors] ||= {}
      else
        Thread.current[:gitaly_feature_flag_actors] ||= {}
      end
    end

    def self.raise_if_concurrent_ruby!
      Gitlab::Utils.raise_if_concurrent_ruby!(:gitaly)
    rescue StandardError => e
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
    end
    private_class_method :raise_if_concurrent_ruby!
  end
end
