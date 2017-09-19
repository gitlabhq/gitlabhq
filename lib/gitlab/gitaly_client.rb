require 'base64'

require 'gitaly'

module Gitlab
  module GitalyClient
    module MigrationStatus
      DISABLED = 1
      OPT_IN = 2
      OPT_OUT = 3
    end

    SERVER_VERSION_FILE = 'GITALY_SERVER_VERSION'.freeze

    MUTEX = Mutex.new
    private_constant :MUTEX

    def self.stub(name, storage)
      MUTEX.synchronize do
        @stubs ||= {}
        @stubs[storage] ||= {}
        @stubs[storage][name] ||= begin
          klass = Gitaly.const_get(name.to_s.camelcase.to_sym).const_get(:Stub)
          addr = address(storage)
          addr = addr.sub(%r{^tcp://}, '') if URI(addr).scheme == 'tcp'
          klass.new(addr, :this_channel_is_insecure)
        end
      end
    end

    def self.clear_stubs!
      MUTEX.synchronize do
        @stubs = nil
      end
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

    # All Gitaly RPC call sites should use GitalyClient.call. This method
    # makes sure that per-request authentication headers are set.
    def self.call(storage, service, rpc, request)
      metadata = request_metadata(storage)
      metadata = yield(metadata) if block_given?
      result = stub(service, storage).__send__(rpc, request, metadata) # rubocop:disable GitlabSecurity/PublicSend

      return Gitlab::GitalyClient::Util.wrap_enumerator(result) if result.is_a?(Enumerator)

      result
    rescue GRPC::BadStatus => e
      raise Gitlab::GitalyClient::Util.unwrap_exception(e)
    end

    def self.request_metadata(storage)
      encoded_token = Base64.strict_encode64(token(storage).to_s)
      { metadata: { 'authorization' => "Bearer #{encoded_token}" } }
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
      is_enabled  = feature_enabled?(feature, status: status)
      metric_name = feature.to_s
      metric_name += "_gitaly" if is_enabled

      Gitlab::Metrics.measure(metric_name) do
        yield is_enabled
      end
    end

    def self.expected_server_version
      path = Rails.root.join(SERVER_VERSION_FILE)
      path.read.chomp
    end

    def self.encode(s)
      s.dup.force_encoding(Encoding::ASCII_8BIT)
    end
  end
end
