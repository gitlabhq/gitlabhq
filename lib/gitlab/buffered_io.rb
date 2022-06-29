# frozen_string_literal: true

module Gitlab
  # Net::BufferedIO is overwritten by webmock but in order to test this class, it needs to inherit from the original BufferedIO.
  # https://github.com/bblimke/webmock/blob/867f4b290fd133658aa9530cba4ba8b8c52c0d35/lib/webmock/http_lib_adapters/net_http.rb#L266
  parent_class = if const_defined?('WebMock::HttpLibAdapters::NetHttpAdapter::OriginalNetBufferedIO') && Rails.env.test?
                   WebMock::HttpLibAdapters::NetHttpAdapter::OriginalNetBufferedIO
                 else
                   Net::BufferedIO
                 end

  class BufferedIo < parent_class
    extend ::Gitlab::Utils::Override

    HEADER_READ_TIMEOUT = 20

    # rubocop: disable Style/RedundantBegin
    # rubocop: disable Style/RedundantReturn
    # rubocop: disable Cop/LineBreakAfterGuardClauses
    # rubocop: disable Layout/EmptyLineAfterGuardClause

    # Original method:
    # https://github.com/ruby/ruby/blob/cdb7d699d0641e8f081d590d06d07887ac09961f/lib/net/protocol.rb#L190-L200
    override :readuntil
    def readuntil(terminator, ignore_eof = false, start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC))
      begin
        until idx = @rbuf.index(terminator)
          if (elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) > HEADER_READ_TIMEOUT
            raise Gitlab::HTTP::HeaderReadTimeout, "Request timed out after reading headers for #{elapsed} seconds"
          end

          rbuf_fill
        end

        return rbuf_consume(idx + terminator.size)
      rescue EOFError
        raise unless ignore_eof
        return rbuf_consume(@rbuf.size)
      end
    end
    # rubocop: disable Style/RedundantBegin
    # rubocop: enable Style/RedundantReturn
    # rubocop: enable Cop/LineBreakAfterGuardClauses
    # rubocop: enable Layout/EmptyLineAfterGuardClause
  end
end
