# frozen_string_literal: true

module Net
  class HTTPResponse
    # rubocop: disable Cop/LineBreakAfterGuardClauses
    # rubocop: disable Cop/LineBreakAroundConditionalBlock
    # rubocop: disable Layout/EmptyLineAfterGuardClause
    # rubocop: disable Style/AndOr
    # rubocop: disable Style/CharacterLiteral
    # rubocop: disable Style/InfiniteLoop

    # Original method:
    # https://github.com/ruby/ruby/blob/v2_7_5/lib/net/http/response.rb#L54-L69
    #
    # Our changes:
    # - Pass along the `start_time` to `Gitlab::HTTP_V2::BufferedIo`, so we can raise a timeout
    #   if reading the headers takes too long.
    # - Limit the regexes to avoid ReDoS attacks.
    def self.each_response_header(sock)
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      key = value = nil
      while true
        uses_buffered_io = sock.is_a?(Gitlab::HTTP_V2::BufferedIo)

        line = uses_buffered_io ? sock.readuntil("\n", true, start_time) : sock.readuntil("\n", true)
        line = line.sub(/\s{0,10}\z/, '')
        break if line.empty?
        if line[0] == ?\s or line[0] == ?\t and value
          # rubocop:disable Gitlab/NoCodeCoverageComment
          # :nocov:
          value << ' ' unless value.empty?
          value << line.strip
          # :nocov:
          # rubocop:enable Gitlab/NoCodeCoverageComment
        else
          yield key, value if key
          key, value = line.strip.split(/\s{0,10}:\s{0,10}/, 2)
          raise Net::HTTPBadResponse, 'wrong header line format' if value.nil?
        end
      end
      yield key, value if key
    end
    # rubocop: enable Cop/LineBreakAfterGuardClauses
    # rubocop: enable Cop/LineBreakAroundConditionalBlock
    # rubocop: enable Layout/EmptyLineAfterGuardClause
    # rubocop: enable Style/AndOr
    # rubocop: enable Style/CharacterLiteral
    # rubocop: enable Style/InfiniteLoop
  end
end
