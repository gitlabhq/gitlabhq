module EE
  module PrometheusMetric
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      has_many :prometheus_alerts, inverse_of: :prometheus_metric
    end
  end
end
