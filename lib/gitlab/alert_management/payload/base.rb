# frozen_string_literal: true

# Representation of a payload of an alert. Defines a constant
# API so that payloads from various sources can be treated
# identically. Subclasses should define how to parse payload
# based on source of alert.
module Gitlab
  module AlertManagement
    module Payload
      class Base
        include ActiveModel::Model
        include Gitlab::Utils::StrongMemoize
        include Gitlab::Routing

        attr_accessor :project, :payload, :integration

        # Any attribute expected to be specifically read from
        # or derived from an alert payload should be defined.
        EXPECTED_PAYLOAD_ATTRIBUTES = [
          :alert_markdown,
          :alert_title,
          :annotations,
          :description,
          :ends_at,
          :environment,
          :environment_name,
          :full_query,
          :generator_url,
          :gitlab_alert,
          :gitlab_fingerprint,
          :gitlab_prometheus_alert_id,
          :gitlab_y_label,
          :has_required_attributes?,
          :hosts,
          :metric_id,
          :metrics_dashboard_url,
          :monitoring_tool,
          :resolved?,
          :runbook,
          :service,
          :severity,
          :starts_at,
          :status,
          :title
        ].freeze

        private_constant :EXPECTED_PAYLOAD_ATTRIBUTES

        # Define expected API for a payload
        EXPECTED_PAYLOAD_ATTRIBUTES.each do |key|
          define_method(key) {}
        end

        SEVERITY_MAPPING = {
          'critical' => :critical,
          'high' => :high,
          'medium' => :medium,
          'low' => :low,
          'info' => :info
        }.freeze

        # Handle an unmapped severity value the same way we treat missing values
        # so we can fallback to alert's default severity `critical`.
        UNMAPPED_SEVERITY = nil

        # Defines a method which allows access to a given
        # value within an alert payload
        #
        # @param key [Symbol] Name expected to be used to reference value
        # @param paths [String, Array<String>, Array<Array<String>>,]
        #              List of (nested) keys at value can be found, the
        #              first to yield a result will be used
        # @param type [Symbol] If value should be converted to another type,
        #              that should be specified here
        # @param fallback [Proc] Block to be executed to yield a value if
        #                 a value cannot be idenitied at any provided paths
        # Example)
        #    attribute :title
        #              paths: [['title'],
        #                     ['details', 'title']]
        #              fallback: Proc.new { 'New Alert' }
        #
        # The above sample definition will define a method
        # called #title which will return the value from the
        # payload under the key `title` if available, otherwise
        # looking under `details.title`. If neither returns a
        # value, the return value will be `'New Alert'`
        def self.attribute(key, paths:, type: nil, fallback: -> { nil })
          define_method(key) do
            strong_memoize(key) do
              paths = Array(paths).first.is_a?(String) ? [Array(paths)] : paths
              value = value_for_paths(paths)
              value = parse_value(value, type) if value

              value.presence || fallback.call
            end
          end
        end

        # Attributes of an AlertManagement::Alert as read
        # directly from a payload. Prefer accessing
        # AlertManagement::Alert directly for read operations.
        def alert_params
          {
            description: description&.truncate(::AlertManagement::Alert::DESCRIPTION_MAX_LENGTH),
            ended_at: ends_at,
            environment: environment,
            fingerprint: gitlab_fingerprint,
            hosts: truncate_hosts(Array(hosts).flatten),
            monitoring_tool: monitoring_tool&.truncate(::AlertManagement::Alert::TOOL_MAX_LENGTH),
            payload: payload,
            project_id: project.id,
            prometheus_alert: gitlab_alert,
            service: service&.truncate(::AlertManagement::Alert::SERVICE_MAX_LENGTH),
            severity: severity,
            started_at: starts_at,
            title: title&.truncate(::AlertManagement::Alert::TITLE_MAX_LENGTH)
          }.transform_values(&:presence).compact
        end

        def gitlab_fingerprint
          strong_memoize(:gitlab_fingerprint) do
            next unless plain_gitlab_fingerprint

            Gitlab::AlertManagement::Fingerprint.generate(plain_gitlab_fingerprint)
          end
        end

        def environment
          strong_memoize(:environment) do
            next unless environment_name

            ::Environments::EnvironmentsFinder
              .new(project, nil, { name: environment_name })
              .execute
              .first
          end
        end

        def resolved?
          status == 'resolved'
        end

        def has_required_attributes?
          true
        end

        def severity
          severity_mapping.fetch(severity_raw.to_s.downcase, UNMAPPED_SEVERITY)
        end

        private

        def plain_gitlab_fingerprint
        end

        def severity_raw
        end

        def severity_mapping
          SEVERITY_MAPPING
        end

        def truncate_hosts(hosts)
          return hosts if hosts.join.length <= ::AlertManagement::Alert::HOSTS_MAX_LENGTH

          hosts.inject([]) do |new_hosts, host|
            remaining_length = ::AlertManagement::Alert::HOSTS_MAX_LENGTH - new_hosts.join.length

            break new_hosts unless remaining_length > 0

            new_hosts << host.to_s.truncate(remaining_length, omission: '')
          end
        end

        # Overriden in EE::Gitlab::AlertManagement::Payload::Generic
        def value_for_paths(paths)
          target_path = paths.find { |path| payload&.dig(*path) }

          payload&.dig(*target_path) if target_path
        end

        def parse_value(value, type)
          case type
          when :time
            parse_time(value)
          when :integer
            parse_integer(value)
          else
            value
          end
        end

        def parse_time(value)
          Time.parse(value).utc
        rescue ArgumentError, TypeError
        end

        def parse_integer(value)
          Integer(value)
        rescue ArgumentError, TypeError
        end
      end
    end
  end
end
