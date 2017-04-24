module Github
  class RateLimit
    SAFE_REMAINING_REQUESTS = 100
    SAFE_RESET_TIME         = 500
    RATE_LIMIT_URL          = '/rate_limit'.freeze

    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def exceed?
      return false unless enabled?

      remaining <= SAFE_REMAINING_REQUESTS
    end

    def remaining
      @remaining ||= body.dig('rate', 'remaining').to_i
    end

    def reset_in
      @reset ||= body.dig('rate', 'reset').to_i
    end

    private

    def response
      connection.get(RATE_LIMIT_URL)
    end

    def body
      @body ||= Oj.load(response.body, class_cache: false, mode: :compat)
    end

    # GitHub Rate Limit API returns 404 when the rate limit is disabled
    def enabled?
      response.status != 404
    end
  end
end
