require 'gitaly'

module Gitlab
  module GitalyClient
    def self.gitaly_address
      if Gitlab.config.gitaly.socket_path
        "unix://#{Gitlab.config.gitaly.socket_path}"
      end
    end

    def self.channel
      return @channel if defined?(@channel)

      @channel =
        if enabled?
          # NOTE: Gitaly currently runs on a Unix socket, so permissions are
          # handled using the file system and no additional authentication is
          # required (therefore the :this_channel_is_insecure flag)
          GRPC::Core::Channel.new(gitaly_address, {}, :this_channel_is_insecure)
        else
          nil
        end
    end

    def self.enabled?
      gitaly_address.present?
    end
  end
end
