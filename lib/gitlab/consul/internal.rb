# frozen_string_literal: true

module Gitlab
  module Consul
    class Internal
      Error = Class.new(StandardError)
      UnexpectedResponseError = Class.new(Gitlab::Consul::Internal::Error)
      SocketError = Class.new(Gitlab::Consul::Internal::Error)
      SSLError = Class.new(Gitlab::Consul::Internal::Error)
      ECONNREFUSED = Class.new(Gitlab::Consul::Internal::Error)

      class << self
        def api_url
          Gitlab.config.consul.api_url.to_s.presence if Gitlab.config.consul
        rescue GitlabSettings::MissingSetting
          Gitlab::AppLogger.error('Consul api_url is not present in config/gitlab.yml')

          nil
        end

        def discover_service(service_name:)
          return unless service_name.present? && api_url

          api_path = URI.join(api_url, '/v1/catalog/service/', URI.encode_www_form_component(service_name)).to_s
          services = json_get(api_path, allow_local_requests: true, open_timeout: 5, read_timeout: 10)

          # Use the first service definition
          service = services&.first

          return unless service

          service_address = service['ServiceAddress'] || service['Address']
          service_port = service['ServicePort']

          [service_address, service_port]
        end

        def discover_prometheus_server_address
          service_address, service_port = discover_service(service_name: 'prometheus')

          return unless service_address && service_port

          "#{service_address}:#{service_port}"
        end

        private

        def json_get(path, options)
          response = get(path, options)
          code = response.try(:code)
          body = response.try(:body)

          raise Consul::Internal::UnexpectedResponseError unless code == 200 && body

          parse_response_body(body)
        end

        def parse_response_body(body)
          Gitlab::Json.parse(body)
        rescue StandardError
          raise Consul::Internal::UnexpectedResponseError
        end

        def get(path, options)
          Gitlab::HTTP.get(path, options)
        rescue ::SocketError
          raise Consul::Internal::SocketError
        rescue OpenSSL::SSL::SSLError
          raise Consul::Internal::SSLError
        rescue Errno::ECONNREFUSED
          raise Consul::Internal::ECONNREFUSED
        rescue StandardError
          raise Consul::Internal::UnexpectedResponseError
        end
      end
    end
  end
end
