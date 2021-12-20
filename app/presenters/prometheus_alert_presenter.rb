# frozen_string_literal: true

class PrometheusAlertPresenter < Gitlab::View::Presenter::Delegated
  presents ::PrometheusAlert, as: :prometheus_alert

  def humanized_text
    operator_text =
      case prometheus_alert.operator
      when 'lt' then s_('PrometheusAlerts|is less than')
      when 'eq' then s_('PrometheusAlerts|is equal to')
      when 'gt' then s_('PrometheusAlerts|exceeded')
      end

    "#{operator_text} #{prometheus_alert.threshold}#{prometheus_alert.prometheus_metric.unit}"
  end
end
