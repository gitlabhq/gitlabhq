require 'gitaly'

module Gitlab
  module GitalyClient
    SERVER_VERSION_FILE = 'GITALY_SERVER_VERSION'.freeze

    def self.configure_channel(shard, socket_path)
      @channel ||= {}
      @channel[shard] = new_channel("unix://#{socket_path}")
    end

    def self.new_channel(address)
      # NOTE: Gitaly currently runs on a Unix socket, so permissions are
      # handled using the file system and no additional authentication is
      # required (therefore the :this_channel_is_insecure flag)
      GRPC::Core::Channel.new(address, {}, :this_channel_is_insecure)
    end

    def self.get_channel(shard)
      @channel.fetch(shard)
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
