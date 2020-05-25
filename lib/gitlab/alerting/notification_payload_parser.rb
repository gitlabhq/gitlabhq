# frozen_string_literal: true

module Gitlab
  module Alerting
    class NotificationPayloadParser
      BadPayloadError = Class.new(StandardError)

      DEFAULT_TITLE = 'New: Incident'
      DEFAULT_SEVERITY = 'critical'

      def initialize(payload)
        @payload = payload.to_h.with_indifferent_access
      end

      def self.call(payload)
        new(payload).call
      end

      def call
        {
          'annotations' => annotations,
          'startsAt' => starts_at
        }.compact
      end

      private

      attr_reader :payload

      def title
        payload[:title].presence || DEFAULT_TITLE
      end

      def severity
        payload[:severity].presence || DEFAULT_SEVERITY
      end

      def fingerprint
        Gitlab::AlertManagement::Fingerprint.generate(payload[:fingerprint])
      end

      def annotations
        primary_params
          .reverse_merge(flatten_secondary_params)
          .transform_values(&:presence)
          .compact
      end

      def primary_params
        {
          'title' => title,
          'description' => payload[:description],
          'monitoring_tool' => payload[:monitoring_tool],
          'service' => payload[:service],
          'hosts' => hosts.presence,
          'severity' => severity,
          'fingerprint' => fingerprint
        }
      end

      def hosts
        Array(payload[:hosts]).reject(&:blank?)
      end

      def current_time
        Time.current.change(usec: 0).rfc3339
      end

      def starts_at
        Time.parse(payload[:start_time].to_s).rfc3339
      rescue ArgumentError
        current_time
      end

      def secondary_params
        payload.except(:start_time)
      end

      def flatten_secondary_params
        Gitlab::Utils::SafeInlineHash.merge_keys!(secondary_params)
      rescue ArgumentError
        raise BadPayloadError, 'The payload is too big'
      end
    end
  end
end
