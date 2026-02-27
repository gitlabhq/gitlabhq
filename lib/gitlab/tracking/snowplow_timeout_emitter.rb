# frozen_string_literal: true

module Gitlab
  module Tracking
    class SnowplowTimeoutEmitter < SnowplowTracker::AsyncEmitter
      extend ::Gitlab::Utils::Override

      HTTP_TIMEOUT = 30

      # this method is a copy of the gem's implementation with added http timeouts
      override :http_post
      def http_post(payload)
        logger.info("Sending POST request to #{@collector_uri}...")
        logger.debug("Payload: #{payload}")
        destination = URI(@collector_uri)
        http = Net::HTTP.new(destination.host, destination.port)
        http.open_timeout = HTTP_TIMEOUT
        http.read_timeout = HTTP_TIMEOUT
        http.use_ssl = true if destination.scheme == 'https'
        request = Net::HTTP::Post.new(destination.request_uri)
        request.body = payload.to_json
        request.set_content_type('application/json; charset=utf-8')
        response = http.request(request)
        logger.add(good_status_code?(response.code) ? Logger::INFO : Logger::WARN) do
          "POST request to #{@collector_uri} finished with status code #{response.code}"
        end

        response
      end
    end
  end
end
