module Geo
  class NodeStatusService
    include HTTParty

    KEYS = %w(health repositories repositories_synced repositories_failed).freeze

    # HTTParty timeout
    default_timeout Gitlab.config.gitlab.geo_status_timeout

    def call(status_url)
      values =
        begin
          response = self.class.get(status_url, headers: headers)

          if response.success? || response.redirection?
            response.parsed_response.values_at(*keys)
          else
            ["Could not connect to Geo node - HTTP Status Code: #{response.code}"]
          end
        rescue HTTParty::Error, Errno::ECONNREFUSED => e
          [e.message]
        end

      GeoNodeStatus.new(KEYS.zip(values).to_h)
    end

    private

    def headers
      Gitlab::Geo::BaseRequest.new.headers
    end
  end
end
