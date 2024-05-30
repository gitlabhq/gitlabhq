# frozen_string_literal: true

module Gitlab
  module AlertManagement
    module Payload
      # Attribute mapping for alerts via prometheus alerting integration.
      class Prometheus < Base
        extend Gitlab::Utils::Override

        attribute :alert_markdown, paths: %w[annotations gitlab_incident_markdown]
        attribute :annotations, paths: 'annotations'
        attribute :description, paths: %w[annotations description]
        attribute :ends_at, paths: 'endsAt', type: :time
        attribute :environment_name, paths: %w[labels gitlab_environment_name]
        attribute :generator_url, paths: %w[generatorURL]
        attribute :gitlab_y_label,
          paths: [%w[annotations gitlab_y_label],
                  %w[annotations title],
                  %w[annotations summary],
                  %w[labels alertname]]
        attribute :runbook, paths: %w[annotations runbook]
        attribute :starts_at,
          paths: 'startsAt',
          type: :time,
          fallback: -> { Time.current.utc }
        attribute :status, paths: 'status'
        attribute :title,
          paths: [%w[annotations title],
                  %w[annotations summary],
                  %w[labels alertname]]
        attribute :starts_at_raw,
          paths: [%w[startsAt]]
        private :starts_at_raw

        attribute :severity_raw, paths: %w[labels severity]
        private :severity_raw

        METRIC_TIME_WINDOW = 30.minutes

        ADDITIONAL_SEVERITY_MAPPING = {
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

        def has_required_attributes?
          project && title && starts_at_raw
        end

        def source
          integration&.name || monitoring_tool
        end

        private

        override :severity_mapping
        def severity_mapping
          super.merge(ADDITIONAL_SEVERITY_MAPPING)
        end

        def plain_gitlab_fingerprint
          [starts_at_raw, title, full_query].join('/')
        end
      end
    end
  end
end

Gitlab::AlertManagement::Payload::Prometheus.prepend_mod
