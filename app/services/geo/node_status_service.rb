module Geo
  class NodeStatusService
    include HTTParty

    # HTTParty timeout
    default_timeout Gitlab.config.gitlab.geo_status_timeout

    def call(status_url)
      keys = %w(health repositories repositories_synced repositories_failed)
      values =
        begin
          response = self.class.get(status_url,
                                    headers: {
                                      'Content-Type' => 'application/json',
                                      'PRIVATE-TOKEN' => private_token
                                    })

          if response.success? || response.redirection?
            response.parsed_response.values_at(*keys)
          else
            ["Could not connect to Geo node - HTTP Status Code: #{response.code}"]
          end
        rescue HTTParty::Error, Errno::ECONNREFUSED => e
          [e.message]
        end

      GeoNodeStatus.new(keys.zip(values).to_h)
    end

    private

    def private_token
      # TODO: should we ask admin user to be defined as part of configuration?
      @private_token ||= User.find_by(admin: true).authentication_token
    end
  end
end
