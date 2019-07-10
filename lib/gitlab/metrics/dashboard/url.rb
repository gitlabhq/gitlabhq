# frozen_string_literal: true

# Manages url matching for metrics dashboards.
module Gitlab
  module Metrics
    module Dashboard
      class Url
        class << self
          # Matches urls for a metrics dashboard. This could be
          # either the /metrics endpoint or the /metrics_dashboard
          # endpoint.
          #
          # EX - https://<host>/<namespace>/<project>/environments/<env_id>/metrics
          def regex
            %r{
              (?<url>
                #{Regexp.escape(Gitlab.config.gitlab.url)}
                \/#{Project.reference_pattern}
                (?:\/\-)?
                \/environments
                \/(?<environment>\d+)
                \/metrics
                (?<query>
                  \?[a-z0-9_=-]+
                  (&[a-z0-9_=-]+)*
                )?
                (?<anchor>\#[a-z0-9_-]+)?
              )
            }x
          end

          # Builds a metrics dashboard url based on the passed in arguments
          def build_dashboard_url(*args)
            Gitlab::Routing.url_helpers.metrics_dashboard_namespace_project_environment_url(*args)
          end
        end
      end
    end
  end
end
