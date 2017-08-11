module Github
  class Client
    TIMEOUT = 60

    attr_reader :connection, :rate_limit

    def initialize(options)
      @connection = Faraday.new(url: options.fetch(:url, root_endpoint)) do |faraday|
        faraday.options.open_timeout = options.fetch(:timeout, TIMEOUT)
        faraday.options.timeout = options.fetch(:timeout, TIMEOUT)
        faraday.authorization 'token', options.fetch(:token)
        faraday.adapter :net_http
        faraday.ssl.verify = verify_ssl
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
      github_omniauth_provider.dig('args', 'client_options', 'site')
    end

    def verify_ssl
      # If there is no config, we're connecting to github.com
      # and we should verify ssl.
      github_omniauth_provider.fetch('verify_ssl', true)
    end

    def github_endpoint
      OmniAuth::Strategies::GitHub.default_options[:client_options][:site]
    end

    def github_omniauth_provider
      @github_omniauth_provider ||=
        Gitlab.config.omniauth.providers
              .find { |provider| provider.name == 'github' }
              .to_h
    end
  end
end
