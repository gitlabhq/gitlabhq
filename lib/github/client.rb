module Github
  class Client
    attr_reader :connection, :rate_limit

    def initialize(options)
      @connection = Faraday.new(url: options.fetch(:url, root_endpoint)) do |faraday|
        faraday.options.open_timeout = options.fetch(:timeout, 60)
        faraday.options.timeout = options.fetch(:timeout, 60)
        faraday.authorization 'token', options.fetch(:token)
        faraday.adapter :net_http
      end

      @rate_limit = RateLimit.new(connection)
    end

    def get(url, query = {})
      exceed, reset_in = rate_limit.get
      sleep reset_in if exceed

      Github::Response.new(connection.get(url, query))
    end

    private

    def root_endpoint
      custom_endpoint || github_endpoint
    end

    def custom_endpoint
      Gitlab.config.omniauth.providers
                            .find { |provider| provider.name == 'github' }
                            .to_h
                            .dig('args', 'client_options', 'site')
    end

    def github_endpoint
      OmniAuth::Strategies::GitHub.default_options[:client_options][:site]
    end
  end
end
