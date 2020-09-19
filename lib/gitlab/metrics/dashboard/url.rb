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
          DASH_PATTERN = '(?:/-)'

          # Matches urls for a metrics dashboard.
          # This regex needs to match the old metrics URL, the new metrics URL,
          # and the dashboard URL (inline_metrics_redactor_filter.rb
          # uses this regex to match against the dashboard URL.)
          #
          # EX - Old URL: https://<host>/<namespace>/<project>/environments/<env_id>/metrics
          # OR
          # New URL: https://<host>/<namespace>/<project>/-/metrics?environment=<env_id>
          # OR
          # dashboard URL: https://<host>/<namespace>/<project>/environments/<env_id>/metrics_dashboard
          def metrics_regex
            strong_memoize(:metrics_regex) do
              regex_for_project_metrics(
                %r{
                    ( #{environment_metrics_regex} ) | ( #{non_environment_metrics_regex} )
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
                  #{DASH_PATTERN}?
                  /grafana
                  /metrics_dashboard
                }x
              )
            end
          end

          # Matches dashboard urls for a metric chart embed
          # for cluster metrics.
          # This regex needs to match the dashboard URL as well, not just the trigger URL.
          # The inline_metrics_redactor_filter.rb uses this regex to match against
          # the dashboard URL.
          #
          # EX - https://<host>/<namespace>/<project>/-/clusters/<cluster_id>/?group=Cluster%20Health&title=Memory%20Usage&y_label=Memory%20(GiB)
          # dashboard URL - https://<host>/<namespace>/<project>/-/clusters/<cluster_id>/metrics_dashboard?group=Cluster%20Health&title=Memory%20Usage&y_label=Memory%20(GiB)
          def clusters_regex
            strong_memoize(:clusters_regex) do
              regex_for_project_metrics(
                %r{
                  #{DASH_PATTERN}?
                  /clusters
                  /(?<cluster_id>\d+)
                  /?
                  ( (/metrics) | ( /metrics_dashboard\.json ) )?
                }x
              )
            end
          end

          # Matches dashboard urls for a metric chart embed
          # for a specifc firing GitLab alert
          #
          # EX - https://<host>/<namespace>/<project>/prometheus/alerts/<alert_id>/metrics_dashboard
          def alert_regex
            strong_memoize(:alert_regex) do
              regex_for_project_metrics(
                %r{
                  #{DASH_PATTERN}?
                  /prometheus
                  /alerts
                  /(?<alert>\d+)
                  /metrics_dashboard(\.json)?
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

          def environment_metrics_regex
            %r{
              #{DASH_PATTERN}?
              /environments
              /(?<environment>\d+)
              /(metrics_dashboard|metrics)
            }x
          end

          def non_environment_metrics_regex
            %r{
              #{DASH_PATTERN}
              /metrics
              (?=                             # Lookahead to ensure there is an environment query param
                \?
                .*
                environment=(?<environment>\d+)
                .*
              )
            }x
          end

          def regex_for_project_metrics(path_suffix_pattern)
            %r{
              ^(?<url>
                #{gitlab_host_pattern}
                #{project_path_pattern}
                #{path_suffix_pattern}
                #{QUERY_PATTERN}
                #{ANCHOR_PATTERN}
              )$
            }x
          end

          def gitlab_host_pattern
            Regexp.escape(gitlab_domain)
          end

          def project_path_pattern
            "\/#{Project.reference_pattern}"
          end

          def gitlab_domain
            Gitlab.config.gitlab.url
          end
        end
      end
    end
  end
end
