module Github
  class RateLimit
    SAFE_REMAINING_REQUESTS = 100
    SAFE_RESET_TIME         = 500
    RATE_LIMIT_URL          = '/rate_limit'.freeze

    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def get
      response = connection.get(RATE_LIMIT_URL)

      # GitHub Rate Limit API returns 404 when the rate limit is disabled
      return false unless response.status != 404

      body      = Oj.load(response.body, class_cache: false, mode: :compat)
      remaining = body.dig('rate', 'remaining').to_i
      reset_in  = body.dig('rate', 'reset').to_i
      exceed    = remaining <= SAFE_REMAINING_REQUESTS

      [exceed, reset_in]
    end
  end
end
