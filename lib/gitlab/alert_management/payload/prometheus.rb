# frozen_string_literal: true

# Attribute mapping for alerts via prometheus alerting integration.
module Gitlab
  module AlertManagement
    module Payload
      class Prometheus < Base
        attribute :alert_markdown, paths: %w(annotations gitlab_incident_markdown)
        attribute :annotations, paths: 'annotations'
        attribute :description, paths: %w(annotations description)
        attribute :ends_at, paths: 'endsAt', type: :time
        attribute :environment_name, paths: %w(labels gitlab_environment_name)
        attribute :generator_url, paths: %w(generatorURL)
        attribute :gitlab_y_label,
                  paths: [%w(annotations gitlab_y_label),
                          %w(annotations title),
                          %w(annotations summary),
                          %w(labels alertname)]
        attribute :runbook, paths: %w(annotations runbook)
        attribute :starts_at,
                  paths: 'startsAt',
                  type: :time,
                  fallback: -> { Time.current.utc }
        attribute :status, paths: 'status'
        attribute :title,
                  paths: [%w(annotations title),
                          %w(annotations summary),
                          %w(labels alertname)]

        attribute :starts_at_raw,
                  paths: [%w(startsAt)]
        private :starts_at_raw

        METRIC_TIME_WINDOW = 30.minutes

        def monitoring_tool
          Gitlab::AlertManagement::Payload::MONITORING_TOOLS[:prometheus]
        end

        # Parses `g0.expr` from `generatorURL`.
        #
        # Example: http://localhost:9090/graph?g0.expr=vector%281%29&g0.tab=1
        def full_query
          return unless generator_url

          uri = URI(generator_url)

          Rack::Utils.parse_query(uri.query).fetch('g0.expr')
        rescue URI::InvalidURIError, KeyError
        end

        def metrics_dashboard_url
          return unless environment && full_query && title

          metrics_dashboard_project_environment_url(
            project,
            environment,
            embed_json: dashboard_json,
            embedded: true,
            **alert_embed_window_params
          )
        end

        def has_required_attributes?
          project && title && starts_at_raw
        end

        private

        def plain_gitlab_fingerprint
          [starts_at_raw, title, full_query].join('/')
        end

        # Formatted for parsing by JS
        def alert_embed_window_params
          {
            start: (starts_at - METRIC_TIME_WINDOW).utc.strftime('%FT%TZ'),
            end: (starts_at + METRIC_TIME_WINDOW).utc.strftime('%FT%TZ')
          }
        end

        def dashboard_json
          {
            panel_groups: [{
              panels: [{
                type: 'area-chart',
                title: title,
                y_label: gitlab_y_label,
                metrics: [{
                  query_range: full_query
                }]
              }]
            }]
          }.to_json
        end
      end
    end
  end
end
