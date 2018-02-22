module Gitlab
  class SslChecker
    attr_reader :remote_host, :remote_port, :error

    def initialize(host, port)
      @host = host
      @port = port
    end

    def remote
      "#{@host}:#{@port}"
    end

    def check
      tcp_client = TCPSocket.new(@host, @port)
      @ssl_client = OpenSSL::SSL::SSLSocket.new tcp_client, ssl_context
      @ssl_client.connect
      @ssl_client.close
      return true
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET,
           Errno::EHOSTUNREACH, SocketError => e
      @error = 'Network Failure: ' + e.message
    rescue OpenSSL::SSL::SSLError => e
      @error = 'SSL Error: ' + e.message
    end

    def output
      puts '---'
      puts 'Certificate chain'
      @ssl_client.peer_cert_chain.each_with_index do |cert, i|
        puts "#{i}: s: #{cert.subject}\n #{cert.issuer}"
      end
      puts '---'
      puts '---Server certificate---'
      puts @ssl_client.peer_cert
      puts "\n---Chain Certificates---"
      @ssl_client.peer_cert_chain.each { |x| puts x }
    end

    private

    def ssl_context
      context = OpenSSL::SSL::SSLContext.new
      context.verify_mode = OpenSSL::SSL::VERIFY_PEER
      cert_store = OpenSSL::X509::Store.new
      cert_store.set_default_paths
      context.cert_store = cert_store
      context
    end
  end
end
