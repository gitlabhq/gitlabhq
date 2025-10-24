# frozen_string_literal: true

# Deprecated: https://gitlab.com/gitlab-org/gitlab/-/issues/560601
#   Remove with PrometheusIntegration mutations during any major release.
#   Also remove any remaining Integrations::Prometheus records from the database.
module Integrations
  class Prometheus < Integration
  end
end
