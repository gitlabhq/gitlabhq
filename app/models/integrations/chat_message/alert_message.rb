# frozen_string_literal: true

module Integrations
  module ChatMessage
    class AlertMessage < BaseMessage
      attr_reader :title
      attr_reader :alert_url
      attr_reader :severity
      attr_reader :events
      attr_reader :status
      attr_reader :started_at

      def initialize(params)
        @project_name = params[:project_name] || params.dig(:project, :path_with_namespace)
        @project_url = params.dig(:project, :web_url) || params[:project_url]
        @title = params.dig(:object_attributes, :title)
        @alert_url = params.dig(:object_attributes, :url)
        @severity = params.dig(:object_attributes, :severity)
        @events = params.dig(:object_attributes, :events)
        @status = params.dig(:object_attributes, :status)
        @started_at = params.dig(:object_attributes, :started_at)
      end

      def attachments
        [{
          title: title,
          title_link: alert_url,
          color: attachment_color,
          fields: attachment_fields
        }]
      end

      def message
        "Alert firing in #{project_name}"
      end

      private

      def attachment_color
        "#C95823"
      end

      def attachment_fields
        [
          {
            title: "Severity",
            value: severity.to_s.humanize,
            short: true
          },
          {
            title: "Events",
            value: events,
            short: true
          },
          {
            title: "Status",
            value: status.to_s.humanize,
            short: true
          },
          {
            title: "Start time",
            value: format_time(started_at),
            short: true
          }
        ]
      end

      # This formats time into the following format
      # April 23rd, 2020 1:06AM UTC
      def format_time(time)
        time = Time.zone.parse(time.to_s)
        time.strftime("%B #{time.day.ordinalize}, %Y %l:%M%p %Z")
      end
    end
  end
end
