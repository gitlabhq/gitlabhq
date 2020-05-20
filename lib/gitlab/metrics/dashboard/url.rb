# frozen_string_literal: true

# Manages url matching for metrics dashboards.
module Gitlab
  module Metrics
    module Dashboard
      class Url
        class << self
          include Gitlab::Utils::StrongMemoize

          QUERY_PATTERN = '(?<query>\?[a-zA-Z0-9%.()+_=-]+(&[a-zA-Z0-9%.()+_=-]+)*)?'
          ANCHOR_PATTERN = '(?<anchor>\#[a-z0-9_-]+)?'
          OPTIONAL_DASH_PATTERN = '(?:/-)?'

          # Matches urls for a metrics dashboard. This could be
          # either the /metrics endpoint or the /metrics_dashboard
          # endpoint.
          #
          # EX - https://<host>/<namespace>/<project>/environments/<env_id>/metrics
          def metrics_regex
            strong_memoize(:metrics_regex) do
              regex_for_project_metrics(
                %r{
                    /environments
                    /(?<environment>\d+)
                    /(metrics_dashboard|metrics)
                }x
              )
            end
          end

          # Matches dashboard urls for a Grafana embed.
          #
          # EX - https://<host>/<namespace>/<project>/grafana/metrics_dashboard
          def grafana_regex
            strong_memoize(:grafana_regex) do
              regex_for_project_metrics(
                %r{
                  /grafana
                  /metrics_dashboard
                }x
              )
            end
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

          def regex_for_project_metrics(path_suffix_pattern)
            %r{
              (?<url>
                #{gitlab_host_pattern}
                #{project_path_pattern}
                #{OPTIONAL_DASH_PATTERN}
                #{path_suffix_pattern}
                #{QUERY_PATTERN}
                #{ANCHOR_PATTERN}
              )
            }x
          end

          def gitlab_host_pattern
            Regexp.escape(Gitlab.config.gitlab.url)
          end

          def project_path_pattern
            "\/#{Project.reference_pattern}"
          end
        end
      end
    end
  end
end

Gitlab::Metrics::Dashboard::Url.extend_if_ee('::EE::Gitlab::Metrics::Dashboard::Url')
