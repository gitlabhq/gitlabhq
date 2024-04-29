# frozen_string_literal: true

require 'rails'
require 'net/http'
require 'webmock' if Rails.env.test?

# The Ruby 3.2 does change Net protocol. Please see;
# https://github.com/ruby/ruby/blob/ruby_3_2/lib/net/protocol.rb#L194-L206
# vs https://github.com/ruby/ruby/blob/ruby_3_1/lib/net/protocol.rb#L190-L200
NET_PROTOCOL_VERSION_0_2_0 = Gem::Version.new(Net::Protocol::VERSION) >= Gem::Version.new('0.2.0')

module Gitlab
  module HTTP_V2
    # Net::BufferedIO is overwritten by webmock but in order to test this class,
    # it needs to inherit from the original BufferedIO.
    # https://github.com/bblimke/webmock/blob/867f4b290fd133658aa9530cba4ba8b8c52c0d35/lib/webmock/http_lib_adapters/net_http.rb#L266
    parent_class = if const_defined?('WebMock::HttpLibAdapters::NetHttpAdapter::OriginalNetBufferedIO') &&
        Rails.env.test?
                     WebMock::HttpLibAdapters::NetHttpAdapter::OriginalNetBufferedIO
                   else
                     Net::BufferedIO
                   end

    class BufferedIo < parent_class
      HEADER_READ_TIMEOUT = 20

      # rubocop: disable Style/RedundantReturn
      # rubocop: disable Cop/LineBreakAfterGuardClauses
      # rubocop: disable Layout/EmptyLineAfterGuardClause

      # Original method:
      # https://github.com/ruby/ruby/blob/cdb7d699d0641e8f081d590d06d07887ac09961f/lib/net/protocol.rb#L190-L200
      def readuntil(terminator, ignore_eof = false, start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC))
        if NET_PROTOCOL_VERSION_0_2_0
          offset = @rbuf_offset
          begin
            until idx = @rbuf.index(terminator, offset) # rubocop:disable Lint/AssignmentInCondition
              if (elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) > HEADER_READ_TIMEOUT
                raise Gitlab::HTTP_V2::HeaderReadTimeout,
                  "Request timed out after reading headers for #{elapsed} seconds"
              end

              offset = @rbuf.bytesize
              rbuf_fill
            end

            return rbuf_consume(idx + terminator.bytesize - @rbuf_offset)
          rescue EOFError
            raise unless ignore_eof
            return rbuf_consume(@rbuf.size)
          end
        else
          begin
            until idx = @rbuf.index(terminator) # rubocop:disable Lint/AssignmentInCondition
              if (elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) > HEADER_READ_TIMEOUT
                raise Gitlab::HTTP_V2::HeaderReadTimeout,
                  "Request timed out after reading headers for #{elapsed} seconds"
              end

              rbuf_fill
            end

            return rbuf_consume(idx + terminator.size)
          rescue EOFError
            raise unless ignore_eof
            return rbuf_consume(@rbuf.size)
          end
        end
      end
      # rubocop: enable Style/RedundantReturn
      # rubocop: enable Cop/LineBreakAfterGuardClauses
      # rubocop: enable Layout/EmptyLineAfterGuardClause
    end
  end
end
