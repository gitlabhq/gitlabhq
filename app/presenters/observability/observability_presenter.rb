# frozen_string_literal: true

module Observability
  class ObservabilityPresenter
    PATHS = {
      'services' => 'Services',
      'traces-explorer' => 'Traces Explorer',
      'logs/logs-explorer' => 'Logs Explorer',
      'metrics-explorer/summary' => 'Metrics Explorer',
      'infrastructure-monitoring/hosts' => 'Infrastructure Monitoring',
      'dashboard' => 'Dashboard',
      'messaging-queues' => 'Messaging Queues',
      'api-monitoring/explorer' => 'API Monitoring',
      'alerts' => 'Alerts',
      'exceptions' => 'Exceptions',
      'service-map' => 'Service Map',
      'settings' => 'Settings'
    }.freeze

    def initialize(group, path)
      @group = group
      @path = path
    end

    def title
      PATHS.fetch(@path, 'Observability')
    end

    def auth_tokens
      formatted_auth_tokens
    end

    def url_with_path
      return unless observability_setting&.o11y_service_url

      ::URI.join(observability_setting.o11y_service_url, @path)
    end

    def to_h
      {
        o11y_url: observability_setting&.o11y_service_url,
        path: @path,
        auth_tokens: formatted_auth_tokens,
        title: title
      }
    end

    private

    attr_reader :group, :path

    def observability_setting
      @observability_setting ||= @group.observability_group_o11y_setting
    end

    def formatted_auth_tokens
      return {} unless observability_setting

      tokens = Observability::O11yToken.generate_tokens(observability_setting)
      tokens.transform_keys { |key| key.to_s.underscore }
    rescue StandardError => e
      Gitlab::ErrorTracking.log_exception(e)

      {}
    end
  end
end
