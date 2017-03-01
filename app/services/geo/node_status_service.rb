module Geo
  class NodeStatusService
    include HTTParty

    # HTTParty timeout
    default_timeout Gitlab.config.gitlab.geo_status_timeout

    def call(status_url)
      response = self.class.get(status_url,
                                headers: {
                                  'Content-Type' => 'application/json',
                                  'PRIVATE-TOKEN' => private_token
                                })

      values =
        if response.code >= 200 && response.code < 300
          keys = GeoNode::Status.members.map(&:to_s)
          response.parsed_response.values_at(*keys)
        else
          ["Could not connect to Geo node - HTTP Status Code: #{response.code}"]
        end

      GeoNode::Status.new(*values)
    rescue HTTParty::Error, Errno::ECONNREFUSED => e
      GeoNode::Status.new(ActionView::Base.full_sanitizer.sanitize(e.message))
    end

    private

    def private_token
      # TODO: should we ask admin user to be defined as part of configuration?
      @private_token ||= User.find_by(admin: true).authentication_token
    end
  end
end
