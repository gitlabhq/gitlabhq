module Github
  class Client
    attr_reader :connection

    def initialize(token)
      @connection = Faraday.new(url: 'https://api.github.com') do |faraday|
        faraday.authorization 'token', token
        faraday.adapter :net_http
      end
    end

    def get(url, query = {})
      rate_limit = RateLimit.new(connection)
      sleep rate_limit.reset_in if rate_limit.exceed?

      response = connection.get(url, query)
      Github::Response.new(response.headers, response.body, response.status)
    end
  end
end
