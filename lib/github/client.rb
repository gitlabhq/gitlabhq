module Github
  class Client
    attr_reader :connection

    def initialize(token = '881a01d03026458e51285a4c7038c9fe4daa5561')
      @connection = Faraday.new(url: 'https://api.github.com') do |faraday|
        faraday.authorization 'token', token
        faraday.adapter :net_http
      end
    end

    def get(url, query = {})
      rate_limit = RateLimit.new(connection)
      sleep rate_limit.reset_in if rate_limit.exceed?

      Github::Response.new(connection.get(url, query))
    end
  end
end
