# frozen_string_literal: true

module Gitlab
  module Prometheus
    class Internal
      def self.uri
        return if listen_address.blank?

        if listen_address.starts_with?('0.0.0.0:')
          # 0.0.0.0:9090
          port = ':' + listen_address.split(':').second
          'http://localhost' + port

        elsif listen_address.starts_with?(':')
          # :9090
          'http://localhost' + listen_address

        elsif listen_address.starts_with?('http')
          # https://localhost:9090
          listen_address

        else
          # localhost:9090
          'http://' + listen_address
        end
      end

      def self.server_address
        uri&.strip&.sub(/^http[s]?:\/\//, '')
      end

      def self.listen_address
        Gitlab.config.prometheus.listen_address.to_s if Gitlab.config.prometheus
      rescue Settingslogic::MissingSetting
        Gitlab::AppLogger.error('Prometheus listen_address is not present in config/gitlab.yml')

        nil
      end

      def self.prometheus_enabled?
        Gitlab.config.prometheus.enable if Gitlab.config.prometheus
      rescue Settingslogic::MissingSetting
        Gitlab::AppLogger.error('prometheus.enable is not present in config/gitlab.yml')

        false
      end
    end
  end
end
