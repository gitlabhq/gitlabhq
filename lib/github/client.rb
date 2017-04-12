module Github
  class Client
    attr_reader :connection

    def initialize(token)
      @connection = Faraday.new(url: 'https://api.github.com') do |faraday|
        faraday.adapter :net_http_persistent
        faraday.response :json, content_type: /\bjson$/
        faraday.authorization 'token', token
        faraday.response :logger
      end
    end

    def get(url, query = {})
      rate_limit = RateLimit.new(connection)
      sleep rate_limit.reset_in if rate_limit.exceed?

      Github::Response.new(connection.get(url, query))
    end
  end
end
