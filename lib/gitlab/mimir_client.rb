# frozen_string_literal: true

module Gitlab
  # Helper methods to interact with Prometheus network services & resources. Needs basic auth.
  class MimirClient < PrometheusClient
    PROMETHEUS_API_ENDPOINT = 'prometheus'

    def initialize(mimir_url:, user:, password:, options: {})
      @mimir_url = mimir_url.chomp('/')

      super("#{@mimir_url}/#{PROMETHEUS_API_ENDPOINT}", options)

      base64_auth = Base64.strict_encode64("#{user}:#{password}")
      @options.merge!(
        headers: {
          "Authorization" => "Basic #{base64_auth}"
        }
      )
    end

    def healthy?
      response = get(api_path('query'), query: 'vector(0)')

      response.code == 200
    rescue StandardError => e
      raise PrometheusClient::UnexpectedResponseError, e.message
    end

    def ready_url
      "#{mimir_url}/ready"
    end

    private

    attr_reader :mimir_url
  end
end
