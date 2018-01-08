module Gitlab
  class TcpChecker
    attr_reader :remote_host, :remote_port, :local_host, :local_port, :error

    def initialize(remote_host, remote_port, local_host = nil, local_port = nil)
      @remote_host = remote_host
      @remote_port = remote_port
      @local_host = local_host
      @local_port = local_port
    end

    def local
      join_host_port(local_host, local_port)
    end

    def remote
      join_host_port(remote_host, remote_port)
    end

    def check(timeout: 10)
      Socket.tcp(
        remote_host, remote_port,
        local_host, local_port,
        connect_timeout: timeout
      ) do |sock|
        @local_port, @local_host = Socket.unpack_sockaddr_in(sock.local_address)
        @remote_port, @remote_host = Socket.unpack_sockaddr_in(sock.remote_address)
      end

      true
    rescue => err
      @error = err

      false
    end

    private

    def join_host_port(host, port)
      host = "[#{host}]" if host.include?(':')

      "#{host}:#{port}"
    end
  end
end
