module Geo
  class NodeStatusService
    include Gitlab::CurrentSettings
    include HTTParty

    KEYS = %w(
      health
      repositories_count
      repositories_synced_count
      repositories_failed_count
      lfs_objects_count
      lfs_objects_synced_count
      attachments_count
      attachments_synced_count
    ).freeze

    def call(geo_node)
      values =
        begin
          response = self.class.get(geo_node.status_url, headers: headers, timeout: timeout)

          if response.success?
            response.parsed_response.values_at(*KEYS)
          else
            message = "Could not connect to Geo node - HTTP Status Code: #{response.code} #{response.message}"
            payload = response.parsed_response
            details =
              if payload.is_a?(Hash)
                payload['message']
              else
                # The return value can be a giant blob of HTML; ignore it
                ''
              end

            Array([message, details].compact.join("\n"))
          end
        rescue HTTParty::Error, Timeout::Error, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED => e
          [e.message]
        end

      GeoNodeStatus.new(KEYS.zip(values).to_h.merge(id: geo_node.id))
    end

    private

    def headers
      Gitlab::Geo::BaseRequest.new.headers
    end

    def timeout
      current_application_settings.geo_status_timeout
    end
  end
end
