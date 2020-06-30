# frozen_string_literal: true

module AlertManagement
  class PrometheusAlertPresenter < AlertManagement::AlertPresenter
    def metrics_dashboard_url
      alerting_alert.metrics_dashboard_url
    end

    private

    def alert_markdown
      alerting_alert.alert_markdown
    end

    def details_list
      alerting_alert.annotation_list
    end

    def metric_embed_for_alert
      alerting_alert.metric_embed_for_alert
    end

    def full_query
      alerting_alert.full_query
    end
  end
end
