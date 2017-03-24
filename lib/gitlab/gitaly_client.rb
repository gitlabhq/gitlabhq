require 'gitaly'

module Gitlab
  module GitalyClient
    SERVER_VERSION_FILE = 'GITALY_SERVER_VERSION'.freeze

    def self.configure_channel(storage, address)
      @addresses ||= {}
      @addresses[storage] = address
      @channels ||= {}
      @channels[storage] = new_channel(address)
    end

    def self.new_channel(address)
      # NOTE: Gitaly currently runs on a Unix socket, so permissions are
      # handled using the file system and no additional authentication is
      # required (therefore the :this_channel_is_insecure flag)
      GRPC::Core::Channel.new(address, {}, :this_channel_is_insecure)
    end

    def self.get_channel(storage)
      @channels[storage]
    end

    def self.get_address(storage)
      @addresses[storage]
    end

    def self.enabled?
      Gitlab.config.gitaly.enabled
    end

    def self.feature_enabled?(feature)
      enabled? && ENV["GITALY_#{feature.upcase}"] == '1'
    end

    def self.migrate(feature)
      is_enabled  = feature_enabled?(feature)
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
  end
end
