# frozen_string_literal: true

class PrometheusAlertPolicy < ::BasePolicy
  delegate { @subject.project }
end
