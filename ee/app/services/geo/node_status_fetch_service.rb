module Geo
  class NodeStatusFetchService
    def call(geo_node)
      return GeoNodeStatus.current_node_status if geo_node.current?

      data = GeoNodeStatus.find_or_initialize_by(geo_node: geo_node).attributes
      data = data.merge(success: false, health_status: 'Offline')

      begin
        response = Gitlab::HTTP.get(geo_node.status_url, allow_local_requests: true, headers: headers, timeout: timeout)
        data[:success] = response.success?

        if response.success?
          data.merge!(response.parsed_response)
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
        data[:health_status] = 'Unhealthy'
      rescue OpenSSL::Cipher::CipherError
        data[:health] = 'Error decrypting the Geo secret from the database. Check that the primary uses the correct db_key_base.'
        data[:health_status] = 'Unhealthy'
      rescue Gitlab::HTTP::Error, Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError => e
        data[:health] = e.message
      end

      GeoNodeStatus.from_json(data.as_json)
    end

    private

    def headers
      Gitlab::Geo::BaseRequest.new.headers
    end

    def timeout
      Gitlab::CurrentSettings.geo_status_timeout
    end
  end
end
