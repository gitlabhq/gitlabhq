require 'gitaly'

module Gitlab
  module GitalyClient
    SERVER_VERSION_FILE = 'GITALY_SERVER_VERSION'.freeze

    # This function is not thread-safe because it updates Hashes in instance variables.
    def self.configure_channels
      @addresses = {}
      @channels = {}
      Gitlab.config.repositories.storages.each do |name, params|
        address = params['gitaly_address']
        unless address.present?
          raise "storage #{name.inspect} is missing a gitaly_address"
        end

        unless URI(address).scheme.in?(%w(tcp unix))
          raise "Unsupported Gitaly address: #{address.inspect} does not use URL scheme 'tcp' or 'unix'"
        end

        @addresses[name] = address
        @channels[name] = new_channel(address)
      end
    end

    def self.new_channel(address)
      address = address.sub(%r{^tcp://}, '') if URI(address).scheme == 'tcp'
      # NOTE: When Gitaly runs on a Unix socket, permissions are
      # handled using the file system and no additional authentication is
      # required (therefore the :this_channel_is_insecure flag)
      # TODO: Add authentication support when Gitaly is running on a TCP socket.
      GRPC::Core::Channel.new(address, {}, :this_channel_is_insecure)
    end

    def self.get_channel(storage)
      if !Rails.env.production? && @channels.nil?
        # In development mode the Rails auto-loader may reset the instance
        # variables of this class. What we do here is not thread-safe. In normal
        # circumstances (including production) these instance variables have
        # been initialized from config/initializers.
        configure_channels
      end

      @channels[storage]
    end

    def self.get_address(storage)
      if !Rails.env.production? && @addresses.nil?
        # In development mode the Rails auto-loader may reset the instance
        # variables of this class. What we do here is not thread-safe. In normal
        # circumstances (including development) these instance variables have
        # been initialized from config/initializers.
        configure_channels
      end

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
