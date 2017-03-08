module Geo
  class NodeStatusService
    include Gitlab::CurrentSettings
    include HTTParty

    KEYS = %w(health repositories_count repositories_synced_count repositories_failed_count).freeze

    # HTTParty timeout
    default_timeout current_application_settings.geo_status_timeout

    def call(status_url)
      values =
        begin
          response = self.class.get(status_url, headers: headers)

          if response.success?
            response.parsed_response.values_at(*KEYS)
          else
            ["Could not connect to Geo node - HTTP Status Code: #{response.code}"]
          end
        rescue HTTParty::Error, Timeout::Error, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED => e
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
