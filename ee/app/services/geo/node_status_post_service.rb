module Geo
  class NodeStatusPostService
    include Gitlab::Geo::LogHelpers

    def execute(status)
      response = Gitlab::HTTP.post(primary_status_url, body: status.attributes, allow_local_requests: true, headers: headers, timeout: timeout)

      unless response.success?
        handle_failure_for(response)
        return false
      end

      true
    rescue Gitlab::Geo::GeoNodeNotFoundError => e
      log_error(e.to_s)
      false
    rescue OpenSSL::Cipher::CipherError => e
      log_error('Error decrypting the Geo secret from the database. Check that the primary uses the correct db_key_base.', e)
      false
    rescue Gitlab::HTTP::Error, Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError => e
      log_error('Failed to post status data to primary', e)
      false
    end

    private

    def handle_failure_for(response)
      message = "Could not connect to Geo primary node - HTTP Status Code: #{response.code} #{response.message}"
      payload = response.parsed_response
      details =
        if payload.is_a?(Hash)
          payload['message']
        else
          # The return value can be a giant blob of HTML; ignore it
          ''
        end

      log_error([message, details].compact.join("\n"))
    end

    def primary_status_url
      primary_node = Gitlab::Geo.primary_node
      raise Gitlab::Geo::GeoNodeNotFoundError.new('Failed to look up Geo primary node in the database') unless primary_node

      primary_node.status_url
    end

    def headers
      Gitlab::Geo::BaseRequest.new.headers
    end

    def timeout
      Gitlab::CurrentSettings.geo_status_timeout
    end
  end
end
