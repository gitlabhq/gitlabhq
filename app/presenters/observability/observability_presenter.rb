# frozen_string_literal: true

module Observability
  class ObservabilityPresenter
    include Gitlab::Utils::StrongMemoize

    PATHS = {
      'services' => 'Observability|Services',
      'traces-explorer' => 'Observability|Traces explorer',
      'logs/logs-explorer' => 'Observability|Logs explorer',
      'metrics-explorer/summary' => 'Observability|Metrics explorer',
      'infrastructure-monitoring/hosts' => 'Observability|Infrastructure monitoring',
      'dashboard' => 'Observability|Dashboard',
      'messaging-queues' => 'Observability|Messaging queues',
      'api-monitoring/explorer' => 'Observability|API monitoring',
      'alerts' => 'Observability|Alerts',
      'exceptions' => 'Observability|Exceptions',
      'service-map' => 'Observability|Service map',
      'settings/channels' => 'Observability|Notification channels'
    }.freeze

    def initialize(group, path)
      @group = group
      @path = path
    end

    def title
      PATHS.fetch(@path, 'Observability')
    end

    def auth_tokens
      return {} unless observability_setting

      tokens = Observability::O11yToken.generate_tokens(observability_setting)
      tokens.transform_keys { |key| key.to_s.underscore }
    rescue StandardError => e
      Gitlab::ErrorTracking.log_exception(e)

      {}
    end
    strong_memoize_attr :auth_tokens

    def url_with_path
      return unless observability_setting&.o11y_service_url

      ::URI.join(observability_setting.o11y_service_url, @path)
    end

    def to_h
      {
        o11y_url: observability_setting&.o11y_service_url,
        path: @path,
        auth_tokens: auth_tokens,
        title: title
      }
    end

    def provisioning?
      auth_tokens&.dig('status') == :provisioning
    end

    private

    attr_reader :group, :path

    def observability_setting
      @observability_setting ||= @group.observability_group_o11y_setting
    end
  end
end
