# frozen_string_literal: true

##
# This class is compatible with IO class (https://ruby-doc.org/core-2.3.1/IO.html)
# source: https://gitlab.com/snippets/1685610
module Gitlab
  class HttpIO
    BUFFER_SIZE = 128.kilobytes

    # Net::HTTP defaults to 2 seconds, short enough that ordinary work between
    # chunk reads - artifact parsing, trace processing, Sidekiq GVL contention -
    # forces a reconnect and defeats the point of a persistent session. Object
    # storage endpoints close idle sockets sooner than this anyway; Net::HTTP
    # detects that before reusing one and reconnects without spending a retry.
    KEEP_ALIVE_TIMEOUT = 30

    # Net::HTTP's current default, set explicitly because the reconnect
    # behavior documented in #persistent_chunk_response depends on it. Not
    # raised: Net::HTTP retries read timeouts, so each extra retry adds another
    # read timeout to the worst case for a single chunk.
    MAX_RETRIES = 1

    InvalidURLError = Class.new(StandardError)
    FailedToGetChunkError = Class.new(StandardError)

    attr_reader :uri, :size
    attr_reader :tell
    attr_reader :chunk, :chunk_range

    alias_method :pos, :tell

    def initialize(url, size)
      raise InvalidURLError unless ::Gitlab::UrlSanitizer.valid?(url)

      @uri = URI(url)
      @size = size
      @tell = 0
      @use_persistent_connection = Feature.enabled?(:http_io_persistent_connections, Feature.current_request)
    end

    def close
      @http_session&.finish
    rescue IOError
      # Raised when the session was never started or is already finished.
    ensure
      @http_session = nil
    end

    def binmode
      # no-op
    end

    def binmode?
      true
    end

    def path
      nil
    end

    def url
      @uri.to_s
    end

    def seek(pos, where = IO::SEEK_SET)
      new_pos =
        case where
        when IO::SEEK_END
          size + pos
        when IO::SEEK_SET
          pos
        when IO::SEEK_CUR
          tell + pos
        else
          -1
        end

      raise 'new position is outside of file' if new_pos < 0 || new_pos > size

      @tell = new_pos
    end

    def eof?
      tell == size
    end

    def each_line
      until eof?
        line = readline
        break if line.nil?

        yield(line)
      end
    end

    # https://www.rubydoc.info/stdlib/core/IO:read says:
    # When this method is called at end of file, it returns nil or "",
    # depending on length: read, read(nil), and read(0) return "",
    # read(positive_integer) returns nil.
    def read(length = nil, outbuf = nil)
      out = length&.positive? ? nil : []

      length ||= size - tell

      until length <= 0 || eof?
        data = get_chunk
        break if data.empty?

        chunk_bytes = [BUFFER_SIZE - chunk_offset, length].min
        data_slice = data.byteslice(0, chunk_bytes)

        out ||= []
        out << data_slice
        @tell += data_slice.bytesize
        length -= data_slice.bytesize
      end

      out = out&.join

      # If outbuf is passed, we put the output into the buffer. This supports IO.copy_stream functionality
      if outbuf && out
        outbuf.replace(out)
      end

      out
    end

    def readline
      out = []

      until eof?
        data = get_chunk
        new_line = data.index("\n")

        if !new_line.nil?
          out << data[0..new_line]
          @tell += new_line + 1
          break
        else
          out << data
          @tell += data.bytesize
        end
      end

      out.join
    end

    def write(data)
      raise NotImplementedError
    end

    def truncate(offset)
      raise NotImplementedError
    end

    def flush
      raise NotImplementedError
    end

    def present?
      true
    end

    private

    ##
    # The below methods are not implemented in IO class
    #
    def in_range?
      @chunk_range&.include?(tell)
    end

    def get_chunk
      unless in_range?
        response = fetch_chunk_response

        raise FailedToGetChunkError, "Unexpected response code: #{response.code}" unless response.code == '200' || response.code == '206'

        @chunk = response.body.force_encoding(Encoding::BINARY)
        @chunk_range = response.content_range

        ##
        # Note: If provider does not return content_range, then we set it as we requested
        # Provider: minio
        # - When the file size is larger than requested Content-range, the Content-range is included in responses with Net::HTTPPartialContent 206
        # - When the file size is smaller than requested Content-range, the Content-range is included in responses with Net::HTTPPartialContent 206
        # Provider: AWS
        # - When the file size is larger than requested Content-range, the Content-range is included in responses with Net::HTTPPartialContent 206
        # - When the file size is smaller than requested Content-range, the Content-range is included in responses with Net::HTTPPartialContent 206
        # Provider: GCS
        # - When the file size is larger than requested Content-range, the Content-range is included in responses with Net::HTTPPartialContent 206
        # - When the file size is smaller than requested Content-range, the Content-range is included in responses with Net::HTTPOK 200
        @chunk_range ||= (chunk_start...(chunk_start + @chunk.bytesize))
      end

      @chunk[chunk_offset..BUFFER_SIZE]
    end

    def fetch_chunk_response
      if @use_persistent_connection
        persistent_chunk_response
      else
        Net::HTTP.start(uri.hostname, uri.port, proxy_from_env: true, use_ssl: use_ssl?) do |http|
          http.request(request)
        end
      end
    end

    # Net::HTTP transparently reconnects and retries the (idempotent) GET once
    # if the server dropped the keep-alive connection between chunks. It also
    # closes the socket before re-raising a transport error, and reconnects on
    # finding a closed socket, so the memoized session self-heals rather than
    # staying wedged after a failed read.
    def persistent_chunk_response
      http_session.request(request)
    rescue EOFError => e
      # ignore_eof: false (see #http_session) turns a connection that dies
      # mid-body into an error rather than a silently truncated chunk. Surface
      # it as the same class as any other failed chunk fetch; the original
      # EOFError remains available as the exception's cause.
      raise FailedToGetChunkError, "Connection closed before the chunk was fully received: #{e.message}"
    end

    def http_session
      # Without explicit timeouts, Net::HTTP defaults to 60 seconds for each
      # of open/read/write, which lets a single unresponsive object storage
      # endpoint stall high-urgency Sidekiq workers for minutes.
      #
      # ignore_eof defaults to true, which silently returns a truncated body
      # when the connection dies mid-response despite a Content-Length header.
      # Raising EOFError instead lets Net::HTTP retry the idempotent GET once
      # on a fresh connection, and fails the read only if that retry fails too.
      #
      # Net::HTTP.start assigns each option to the same-named setter, and
      # silently ignores keys that do not match one - the spec asserts on the
      # options passed here to catch a typo.
      @http_session ||= Net::HTTP.start(
        uri.hostname, uri.port,
        proxy_from_env: true,
        use_ssl: use_ssl?,
        ignore_eof: false,
        keep_alive_timeout: KEEP_ALIVE_TIMEOUT,
        max_retries: MAX_RETRIES,
        **::Gitlab::HTTP::DEFAULT_TIMEOUT_OPTIONS
      )
    end

    def use_ssl?
      uri.scheme == 'https'
    end

    def request
      Net::HTTP::Get.new(uri, { 'accept-encoding' => nil }).tap do |request|
        request.set_range(chunk_start, BUFFER_SIZE)
      end
    end

    def chunk_offset
      tell % BUFFER_SIZE
    end

    def chunk_start
      (tell / BUFFER_SIZE) * BUFFER_SIZE
    end

    def chunk_end
      [chunk_start + BUFFER_SIZE, size].min
    end
  end
end
