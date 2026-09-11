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
    # behavior documented in #fetch_chunk_response depends on it. Not
    # raised: Net::HTTP retries read timeouts, so each extra retry adds another
    # read timeout to the worst case for a single chunk.
    MAX_RETRIES = 1

    # Shared by every chunk an instance fetches, rather than allowed per chunk:
    # a read walks the object BUFFER_SIZE bytes at a time, so a per-chunk
    # allowance would let one unhealthy endpoint stretch a large read by the
    # retry cost multiplied by the chunk count.
    RETRY_BUDGET = 3

    # Doubled per retry and jittered, so concurrent readers of the same
    # unhealthy endpoint do not retry in lockstep. Deliberately short: retries
    # happen inside a user-facing request.
    RETRY_BASE_DELAY = 0.1

    RETRIABLE_RESPONSE_CODES = %w[429 500 502 503 504].freeze

    InvalidURLError = Class.new(StandardError)
    FailedToGetChunkError = Class.new(StandardError)

    # Every error here fails within milliseconds, so a 100ms backoff is worth
    # paying. Timeouts are deliberately excluded: retrying one repeats the full
    # open/read/write wait (10-30s), and no backoff helps an endpoint that
    # already took that long to answer.
    RETRIABLE_ERRORS = [
      EOFError,
      Errno::ECONNABORTED,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EHOSTUNREACH,
      Errno::ENETUNREACH,
      Errno::EPIPE,
      Net::HTTPBadResponse,
      OpenSSL::SSL::SSLError,
      SocketError
    ].freeze

    attr_reader :uri, :size
    attr_reader :tell
    attr_reader :chunk, :chunk_range

    alias_method :pos, :tell

    def initialize(url, size)
      raise InvalidURLError unless ::Gitlab::UrlSanitizer.valid?(url)

      @uri = URI(url)
      @size = size
      @tell = 0
      @retries_used = 0
      @retry_transient_errors = Feature.enabled?(:http_io_retry_transient_errors, Feature.current_request)
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
      unless in_range? || restore_previous_chunk
        retain_current_chunk

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
      return fetch_chunk_response_with_retries if @retry_transient_errors

      fetch_chunk_response_once
    end

    # Net::HTTP transparently reconnects and retries the (idempotent) GET once
    # if the server dropped the keep-alive connection between chunks. It also
    # closes the socket before re-raising a transport error, and reconnects on
    # finding a closed socket, so the memoized session self-heals rather than
    # staying wedged after a failed read.
    def fetch_chunk_response_once
      http_session.request(request)
    rescue EOFError => e
      raise_chunk_error(e)
    end

    # Net::HTTP's own retry happens inside #transport_request, after the TLS
    # handshake in Net::HTTP.start, and never treats a response status as an
    # error - this loop covers both gaps. Repeating a range request is safe:
    # it asks for the same bytes, and no chunk state is assigned until the
    # caller checks the status.
    #
    # Returns the first response not worth another attempt, including a
    # failure response once the retry budget is spent (the caller decides what
    # an unusable response means). Errors are raised from the loop itself.
    def fetch_chunk_response_with_retries
      loop do
        outcome = chunk_attempt
        reason = retry_reason(outcome)

        return outcome if reason.nil?

        if @retries_used >= RETRY_BUDGET
          raise_chunk_error(outcome) if outcome.is_a?(StandardError)

          return outcome
        end

        @retries_used += 1
        retry_counter.increment(reason: reason)
        sleep(retry_delay)
      end
    end

    # Returns the response, or the error the request failed with when that
    # error is worth another attempt. Carrying the failure as a value lets
    # response codes and transport errors reach the same decision.
    def chunk_attempt
      http_session.request(request)
    rescue *RETRIABLE_ERRORS => error
      error
    end

    # nil when the outcome is not worth another attempt.
    def retry_reason(outcome)
      return outcome.class.name if outcome.is_a?(StandardError)

      "http_#{outcome.code}" if RETRIABLE_RESPONSE_CODES.include?(outcome.code)
    end

    # @retries_used spans every chunk this instance fetches (see RETRY_BUDGET),
    # so backoff keeps escalating across chunks instead of restarting per chunk.
    def retry_delay
      RETRY_BASE_DELAY * (2**(@retries_used - 1)) * (0.5 + rand)
    end

    def retry_counter
      Gitlab::Metrics.counter(
        :gitlab_http_io_chunk_retries_total,
        'Chunk requests retried by Gitlab::HttpIO, by failure reason'
      )
    end

    def raise_chunk_error(error)
      raise error unless error.is_a?(EOFError)

      # EOFError means the connection died mid-body (see #http_session's
      # ignore_eof comment). Wrap it so callers get a FailedToGetChunkError;
      # cause: is explicit because the retry loop raises here after the rescue
      # that caught the error has already exited.
      raise FailedToGetChunkError,
        "Connection closed before the chunk was fully received: #{error.message}",
        cause: error
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

    # Reads that walk backwards step in units much smaller than BUFFER_SIZE
    # (Gitlab::Ci::Trace::Stream#read_backward uses 4KB), so a step straddling
    # a chunk boundary asks for the lower chunk, then the upper one to finish
    # the step, then the lower one again for the next step. With a single
    # cached chunk each of those is a request, so a backward pass costs three
    # times the requests and bytes of a forward one. Keeping the chunk we just
    # moved away from - the one such a pass asks for next - brings a boundary
    # crossing back to a single request. Forward reads never revisit a chunk,
    # so they are unaffected either way.
    def restore_previous_chunk
      return false unless @previous_chunk_range&.include?(tell)

      @chunk, @previous_chunk = @previous_chunk, @chunk
      @chunk_range, @previous_chunk_range = @previous_chunk_range, @chunk_range

      true
    end

    def retain_current_chunk
      @previous_chunk = @chunk
      @previous_chunk_range = @chunk_range
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
