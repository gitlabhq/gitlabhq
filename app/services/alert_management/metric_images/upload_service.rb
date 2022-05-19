# frozen_string_literal: true

module AlertManagement
  module MetricImages
    class UploadService < BaseService
      attr_reader :alert, :file, :url, :url_text, :metric

      def initialize(alert, current_user, params = {})
        super

        @alert = alert
        @file = params.fetch(:file)
        @url = params.fetch(:url, nil)
        @url_text = params.fetch(:url_text, nil)
      end

      def execute
        unless can_upload_metrics?
          return ServiceResponse.error(
            message: _("You are not authorized to upload metric images"),
            http_status: :forbidden
          )
        end

        metric = AlertManagement::MetricImage.new(
          alert: alert,
          file: file,
          url: url,
          url_text: url_text
        )

        if metric.save
          ServiceResponse.success(payload: { metric: metric, alert: alert })
        else
          ServiceResponse.error(message: metric.errors.full_messages.join(', '), http_status: :bad_request)
        end
      end

      private

      def can_upload_metrics?
        current_user&.can?(:upload_alert_management_metric_image, alert)
      end
    end
  end
end
