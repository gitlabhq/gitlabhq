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
                #{gitlab_pattern}
                #{project_pattern}
                (?:\/\-)?
                \/environments
                \/(?<environment>\d+)
                \/metrics
                #{query_pattern}
                #{anchor_pattern}
              )
            }x
          end

          # Matches dashboard urls for a Grafana embed.
          #
          # EX - https://<host>/<namespace>/<project>/grafana/metrics_dashboard
          def grafana_regex
            %r{
              (?<url>
                #{gitlab_pattern}
                #{project_pattern}
                (?:\/\-)?
                \/grafana
                \/metrics_dashboard
                #{query_pattern}
                #{anchor_pattern}
              )
            }x
          end

          # Parses query params out from full url string into hash.
          #
          # Ex) 'https://<root>/<project>/<environment>/metrics?title=Title&group=Group'
          #       --> { title: 'Title', group: 'Group' }
          def parse_query(url)
            query_string = URI.parse(url).query.to_s

            CGI.parse(query_string)
              .transform_values { |value| value.first }
              .symbolize_keys
          end

          # Builds a metrics dashboard url based on the passed in arguments
          def build_dashboard_url(*args)
            Gitlab::Routing.url_helpers.metrics_dashboard_namespace_project_environment_url(*args)
          end

          private

          def gitlab_pattern
            Regexp.escape(Gitlab.config.gitlab.url)
          end

          def project_pattern
            "\/#{Project.reference_pattern}"
          end

          def query_pattern
            '(?<query>\?[a-zA-Z0-9%.()+_=-]+(&[a-zA-Z0-9%.()+_=-]+)*)?'
          end

          def anchor_pattern
            '(?<anchor>\#[a-z0-9_-]+)?'
          end
        end
      end
    end
  end
end
