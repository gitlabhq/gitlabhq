# frozen_string_literal: true

module Gitlab
  module Prometheus
    class Internal
      def self.uri
        return if server_address.blank?

        if server_address.starts_with?('0.0.0.0:')
          # 0.0.0.0:9090
          port = ':' + server_address.split(':').second
          'http://localhost' + port

        elsif server_address.starts_with?(':')
          # :9090
          'http://localhost' + server_address

        elsif server_address.starts_with?('http')
          # https://localhost:9090
          server_address

        else
          # localhost:9090
          'http://' + server_address
        end
      end

      def self.server_address
        Gitlab.config.prometheus.server_address.to_s if Gitlab.config.prometheus
      rescue GitlabSettings::MissingSetting
        Gitlab::AppLogger.error('Prometheus server_address is not present in config/gitlab.yml')

        nil
      end

      def self.prometheus_enabled?
        Gitlab.config.prometheus.enabled if Gitlab.config.prometheus
      rescue GitlabSettings::MissingSetting
        Gitlab::AppLogger.error('prometheus.enabled is not present in config/gitlab.yml')

        false
      end
    end
  end
end
