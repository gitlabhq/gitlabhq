# frozen_string_literal: true

class PrometheusAlertEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :title
  expose :query
  expose :threshold
  expose :runbook_url

  expose :operator do |prometheus_alert|
    prometheus_alert.computed_operator
  end

  private

  alias_method :prometheus_alert, :object

  def can_read_prometheus_alerts?
    can?(request.current_user, :read_prometheus_alerts, prometheus_alert.project)
  end
end
