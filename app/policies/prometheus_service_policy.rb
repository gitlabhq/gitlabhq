# frozen_string_literal: true

class PrometheusServicePolicy < ::BasePolicy
  delegate { @subject.project }
end
