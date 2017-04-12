module Github
  class RateLimit
    SAFE_REMAINING_REQUESTS = 100.freeze
    SAFE_RESET_TIME         = 500.freeze

    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def exceed?
      return false unless enabled?

      remaining <= SAFE_REMAINING_REQUESTS
    end

    def remaining
      @remaining ||= response.body.dig('rate', 'remaining').to_i
    end

    def reset_in
      @reset ||= response.body.dig('rate', 'reset').to_i
    end

    private

    def rate_limit_url
      '/rate_limit'
    end

    def response
      @response ||= connection.get(rate_limit_url)
    end

    # GitHub Rate Limit API returns 404 when the rate limit is disabled
    def enabled?
      response.status != 404
    end
  end
end
