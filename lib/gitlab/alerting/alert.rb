# frozen_string_literal: true

module Gitlab
  module Alerting
    class Alert
      include ActiveModel::Model
      include Gitlab::Utils::StrongMemoize
      include Presentable

      attr_accessor :project, :payload

      def gitlab_alert
        strong_memoize(:gitlab_alert) do
          parse_gitlab_alert_from_payload
        end
      end

      def metric_id
        strong_memoize(:metric_id) do
          payload&.dig('labels', 'gitlab_alert_id')
        end
      end

      def gitlab_prometheus_alert_id
        strong_memoize(:gitlab_prometheus_alert_id) do
          payload&.dig('labels', 'gitlab_prometheus_alert_id')
        end
      end

      def title
        strong_memoize(:title) do
          gitlab_alert&.title || parse_title_from_payload
        end
      end

      def description
        strong_memoize(:description) do
          parse_description_from_payload
        end
      end

      def environment
        strong_memoize(:environment) do
          gitlab_alert&.environment || parse_environment_from_payload
        end
      end

      def annotations
        strong_memoize(:annotations) do
          parse_annotations_from_payload || []
        end
      end

      def starts_at
        strong_memoize(:starts_at) do
          parse_datetime_from_payload('startsAt')
        end
      end

      def starts_at_raw
        strong_memoize(:starts_at_raw) do
          payload&.dig('startsAt')
        end
      end

      def ends_at
        strong_memoize(:ends_at) do
          parse_datetime_from_payload('endsAt')
        end
      end

      def full_query
        strong_memoize(:full_query) do
          gitlab_alert&.full_query || parse_expr_from_payload
        end
      end

      def y_label
        strong_memoize(:y_label) do
          parse_y_label_from_payload || title
        end
      end

      def alert_markdown
        strong_memoize(:alert_markdown) do
          parse_alert_markdown_from_payload
        end
      end

      def status
        strong_memoize(:status) do
          payload&.dig('status')
        end
      end

      def firing?
        status == 'firing'
      end

      def resolved?
        status == 'resolved'
      end

      def gitlab_managed?
        metric_id.present?
      end

      def gitlab_fingerprint
        Digest::SHA1.hexdigest(plain_gitlab_fingerprint)
      end

      def valid?
        payload.respond_to?(:dig) && project && title && starts_at
      end

      def present
        super(presenter_class: Projects::Prometheus::AlertPresenter)
      end

      private

      def plain_gitlab_fingerprint
        if gitlab_managed?
          [metric_id, starts_at].join('/')
        else # self managed
          [starts_at, title, full_query].join('/')
        end
      end

      def parse_environment_from_payload
        environment_name = payload&.dig('labels', 'gitlab_environment_name')

        return unless environment_name

        EnvironmentsFinder.new(project, nil, { name: environment_name })
          .find
          &.first
      end

      def parse_gitlab_alert_from_payload
        alerts_found = matching_gitlab_alerts

        return if alerts_found.blank? || alerts_found.size > 1

        alerts_found.first
      end

      def matching_gitlab_alerts
        return unless metric_id || gitlab_prometheus_alert_id

        Projects::Prometheus::AlertsFinder
          .new(project: project, metric: metric_id, id: gitlab_prometheus_alert_id)
          .execute
      end

      def parse_title_from_payload
        payload&.dig('annotations', 'title') ||
          payload&.dig('annotations', 'summary') ||
          payload&.dig('labels', 'alertname')
      end

      def parse_description_from_payload
        payload&.dig('annotations', 'description')
      end

      def parse_annotations_from_payload
        payload&.dig('annotations')&.map do |label, value|
          Alerting::AlertAnnotation.new(label: label, value: value)
        end
      end

      def parse_datetime_from_payload(field)
        value = payload&.dig(field)
        return unless value

        Time.rfc3339(value)
      rescue ArgumentError
      end

      # Parses `g0.expr` from `generatorURL`.
      #
      # Example: http://localhost:9090/graph?g0.expr=vector%281%29&g0.tab=1
      def parse_expr_from_payload
        url = payload&.dig('generatorURL')
        return unless url

        uri = URI(url)

        Rack::Utils.parse_query(uri.query).fetch('g0.expr')
      rescue URI::InvalidURIError, KeyError
      end

      def parse_alert_markdown_from_payload
        payload&.dig('annotations', 'gitlab_incident_markdown')
      end

      def parse_y_label_from_payload
        payload&.dig('annotations', 'gitlab_y_label')
      end
    end
  end
end
