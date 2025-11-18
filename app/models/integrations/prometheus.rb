# frozen_string_literal: true

# Deprecated: https://gitlab.com/gitlab-org/gitlab/-/issues/560601
#   Remove with PrometheusIntegration mutations during any major release.
#   Also remove any remaining Integrations::Prometheus records from the database.
module Integrations
  class Prometheus < Integration
    def self.title
      'Prometheus'
    end

    def self.description
      s_('PrometheusService|Monitor application health with Prometheus metrics and dashboards')
    end

    def self.to_param
      'prometheus'
    end
  end
end
