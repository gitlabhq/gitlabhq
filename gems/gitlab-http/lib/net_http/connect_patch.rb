# frozen_string_literal: true

# This patches Net::HTTP#connect to handle the hostname override patch,
# which is needed for Server Side Request Forgery (SSRF)
# protection. This stopped working in net-http v0.2.2 due to
# https://github.com/ruby/net-http/pull/36.
# https://github.com/ruby/net-http/issues/141 is outstanding to make
# this less hacky, but for now we restore the previous behavior by
# setting the SNI hostname with the hostname override, if available.
require 'net/http'

module Net
  class HTTP < Protocol
    # rubocop:disable Cop/LineBreakAroundConditionalBlock -- This is upstream code
    # rubocop:disable Layout/ArgumentAlignment -- This is upstream code
    # rubocop:disable Layout/AssignmentIndentation -- This is upstream code
    # rubocop:disable Layout/LineEndStringConcatenationIndentation -- This is upstream code
    # rubocop:disable Layout/MultilineOperationIndentation -- This is upstream code
    # rubocop:disable Layout/SpaceInsideBlockBraces -- This is upstream code
    # rubocop:disable Lint/UnusedBlockArgument -- This is upstream code
    # rubocop:disable Metrics/AbcSize -- This is upstream code
    # rubocop:disable Metrics/CyclomaticComplexity -- This is upstream code
    # rubocop:disable Metrics/PerceivedComplexity -- This is upstream code
    # rubocop:disable Naming/RescuedExceptionsVariableName -- This is upstream code
    # rubocop:disable Style/AndOr -- This is upstream code
    # rubocop:disable Style/BlockDelimiters -- This is upstream code
    # rubocop:disable Style/EmptyLiteral -- This is upstream code
    # rubocop:disable Style/IfUnlessModifier -- This is upstream code
    # rubocop:disable Style/LineEndConcatenation -- This is upstream code
    # rubocop:disable Style/MultilineIfThen -- This is upstream code
    # rubocop:disable Style/Next -- This is upstream code
    # rubocop:disable Style/RescueStandardError -- This is upstream code
    # rubocop:disable Style/StringConcatenation -- This is upstream code
    def connect
      if use_ssl?
        # reference early to load OpenSSL before connecting,
        # as OpenSSL may take time to load.
        @ssl_context = OpenSSL::SSL::SSLContext.new
      end

      if proxy? then
        conn_addr = proxy_address
        conn_port = proxy_port
      else
        conn_addr = conn_address
        conn_port = port
      end

      debug "opening connection to #{conn_addr}:#{conn_port}..."
      s = Timeout.timeout(@open_timeout, Net::OpenTimeout) {
        begin
          TCPSocket.open(conn_addr, conn_port, @local_host, @local_port)
        rescue => e
          raise e, "Failed to open TCP connection to " +
            "#{conn_addr}:#{conn_port} (#{e.message})"
        end
      }
      s.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      debug "opened"
      if use_ssl?
        if proxy?
          if @proxy_use_ssl
            proxy_sock = OpenSSL::SSL::SSLSocket.new(s)
            ssl_socket_connect(proxy_sock, @open_timeout)
          else
            proxy_sock = s
          end
          proxy_sock = BufferedIO.new(proxy_sock, read_timeout: @read_timeout,
                                      write_timeout: @write_timeout,
                                      continue_timeout: @continue_timeout,
                                      debug_output: @debug_output)
          buf = +"CONNECT #{conn_address}:#{@port} HTTP/#{HTTPVersion}\r\n" \
            "Host: #{@address}:#{@port}\r\n"
          if proxy_user
            credential = ["#{proxy_user}:#{proxy_pass}"].pack('m0')
            buf << "Proxy-Authorization: Basic #{credential}\r\n"
          end
          buf << "\r\n"
          proxy_sock.write(buf)
          HTTPResponse.read_new(proxy_sock).value
          # assuming nothing left in buffers after successful CONNECT response
        end

        ssl_parameters = Hash.new
        iv_list = instance_variables
        SSL_IVNAMES.each_with_index do |ivname, i|
          if iv_list.include?(ivname)
            value = instance_variable_get(ivname)
            unless value.nil?
              ssl_parameters[SSL_ATTRIBUTES[i]] = value
            end
          end
        end
        @ssl_context.set_params(ssl_parameters)
        unless @ssl_context.session_cache_mode.nil? # a dummy method on JRuby
          @ssl_context.session_cache_mode =
              OpenSSL::SSL::SSLContext::SESSION_CACHE_CLIENT |
                  OpenSSL::SSL::SSLContext::SESSION_CACHE_NO_INTERNAL_STORE
        end
        if @ssl_context.respond_to?(:session_new_cb) # not implemented under JRuby
          @ssl_context.session_new_cb = proc {|sock, sess| @ssl_session = sess }
        end

        # Still do the post_connection_check below even if connecting
        # to IP address
        verify_hostname = @ssl_context.verify_hostname

        # This hack would not be needed with https://github.com/ruby/net-http/issues/141
        address_to_verify = hostname_override || @address

        # Server Name Indication (SNI) RFC 3546/6066
        case address_to_verify
        when Resolv::IPv4::Regex, Resolv::IPv6::Regex
          # don't set SNI, as IP addresses in SNI is not valid
          # per RFC 6066, section 3.

          # Avoid openssl warning
          @ssl_context.verify_hostname = false
        else
          ssl_host_address = address_to_verify
        end

        debug "starting SSL for #{conn_addr}:#{conn_port}..."
        s = OpenSSL::SSL::SSLSocket.new(s, @ssl_context)
        s.sync_close = true
        s.hostname = ssl_host_address if s.respond_to?(:hostname=) && ssl_host_address

        if @ssl_session and
           Process.clock_gettime(Process::CLOCK_REALTIME) < @ssl_session.time.to_f + @ssl_session.timeout
          s.session = @ssl_session
        end
        ssl_socket_connect(s, @open_timeout)
        if (@ssl_context.verify_mode != OpenSSL::SSL::VERIFY_NONE) && verify_hostname
          s.post_connection_check(@address)
        end
        debug "SSL established, protocol: #{s.ssl_version}, cipher: #{s.cipher[0]}"
      end
      @socket = BufferedIO.new(s, read_timeout: @read_timeout,
                               write_timeout: @write_timeout,
                               continue_timeout: @continue_timeout,
                               debug_output: @debug_output)
      @last_communicated = nil
      on_connect
    rescue => exception
      if s
        debug "Conn close because of connect error #{exception}"
        s.close
      end
      raise
    end
    private :connect
    # rubocop:enable Cop/LineBreakAroundConditionalBlock
    # rubocop:enable Layout/ArgumentAlignment
    # rubocop:enable Layout/AssignmentIndentation
    # rubocop:enable Layout/LineEndStringConcatenationIndentation
    # rubocop:enable Layout/MultilineOperationIndentation
    # rubocop:enable Layout/SpaceInsideBlockBraces
    # rubocop:enable Lint/UnusedBlockArgument
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Naming/RescuedExceptionsVariableName
    # rubocop:enable Style/AndOr
    # rubocop:enable Style/BlockDelimiters
    # rubocop:enable Style/EmptyLiteral
    # rubocop:enable Style/IfUnlessModifier
    # rubocop:enable Style/LineEndConcatenation
    # rubocop:enable Style/MultilineIfThen
    # rubocop:enable Style/Next
    # rubocop:enable Style/RescueStandardError
    # rubocop:enable Style/StringConcatenation
  end
end
