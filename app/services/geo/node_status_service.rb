module Geo
  class NodeStatusService
    include Gitlab::CurrentSettings
    include HTTParty

    STATUS_DATA = {
      health: 'Summary of health status',
      db_replication_lag_seconds: 'Database replication lag (seconds)',
      repositories_count: 'Total number of repositories available on primary',
      repositories_synced_count: 'Number of repositories synced on secondary',
      repositories_failed_count: 'Number of repositories failed to sync on secondary',
      lfs_objects_count: 'Total number of LFS objects available on primary',
      lfs_objects_synced_count: 'Number of LFS objects synced on secondary',
      lfs_objects_failed_count: 'Number of LFS objects failed to sync on secondary',
      attachments_count: 'Total number of file attachments available on primary',
      attachments_synced_count: 'Number of attachments synced on secondary',
      attachments_failed_count: 'Number of attachments failed to sync on secondary',
      last_event_id: 'Database ID of the latest event log entry on the primary',
      last_event_timestamp: 'UNIX timestamp of the latest event log entry on the primary',
      cursor_last_event_id: 'Last database ID of the event log processed by the secondary',
      cursor_last_event_timestamp: 'Last UNIX timestamp of the event log processed by the secondary'
    }.freeze

    def call(geo_node)
      data = { id: geo_node.id }

      begin
        response = self.class.get(geo_node.status_url, headers: headers, timeout: timeout)
        data[:success] = response.success?

        if response.success?
          data.merge!(response.parsed_response.symbolize_keys.slice(*STATUS_DATA.keys))
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

          data[:health] = [message, details].compact.join("\n")
        end
      rescue Gitlab::Geo::GeoNodeNotFoundError
        data[:health] = 'This GitLab instance does not appear to be configured properly as a Geo node. Make sure the URLs are using the correct fully-qualified domain names.'
      rescue OpenSSL::Cipher::CipherError
        data[:health] = 'Error decrypting the Geo secret from the database. Check that the primary uses the correct db_key_base.'
      rescue HTTParty::Error, Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError => e
        data[:health] = e.message
      end

      GeoNodeStatus.new(data)
    end

    def status_keys
      STATUS_DATA.stringify_keys.keys
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
