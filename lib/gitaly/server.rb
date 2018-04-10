module Gitaly
  class Server
    def self.all
      Gitlab.config.repositories.storages.keys.map { |s| Gitaly::Server.new(s) }
    end

    attr_reader :storage

    def initialize(storage)
      @storage = storage
    end

    def server_version
      info.server_version
    end

    def git_binary_version
      info.git_version
    end

    def up_to_date?
      server_version == Gitlab::GitalyClient.expected_server_version
    end

    def address
      Gitlab::GitalyClient.address(@storage)
    rescue RuntimeError => e
      "Error getting the address: #{e.message}"
    end

    private

    def info
      @info ||=
        begin
          Gitlab::GitalyClient::ServerService.new(@storage).info
        rescue GRPC::Unavailable, GRPC::GRPC::DeadlineExceeded
          # This will show the server as being out of date
          Gitaly::ServerInfoResponse.new(git_version: '', server_version: '')
        end
    end
  end
end
