# frozen_string_literal: true

module Gitlab
  module AlertManagement
    module Payload
      # Attribute mapping for alerts via prometheus alerting integration.
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

        attribute :severity_raw, paths: %w(labels severity)
        private :severity_raw

        METRIC_TIME_WINDOW = 30.minutes

        SEVERITY_MAP = {
          'critical' => :critical,
          'high' => :high,
          'medium' => :medium,
          'low' => :low,
          'info' => :info,
          's1' => :critical,
          's2' => :high,
          's3' => :medium,
          's4' => :low,
          's5' => :info,
          'p1' => :critical,
          'p2' => :high,
          'p3' => :medium,
          'p4' => :low,
          'p5' => :info,
          'debug' => :info,
          'information' => :info,
          'notice' => :info,
          'warn' => :low,
          'warning' => :low,
          'minor' => :low,
          'error' => :medium,
          'major' => :high,
          'emergency' => :critical,
          'fatal' => :critical,
          'alert' => :medium,
          'page' => :high
        }.freeze

        # Handle an unmapped severity value the same way we treat missing values
        # so we can fallback to alert's default severity `critical`.
        UNMAPPED_SEVERITY = nil

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

        def severity
          return unless severity_raw

          SEVERITY_MAP.fetch(severity_raw.to_s.downcase, UNMAPPED_SEVERITY)
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
