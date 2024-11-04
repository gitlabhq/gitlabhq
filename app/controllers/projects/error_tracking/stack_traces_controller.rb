# frozen_string_literal: true

module Projects
  module ErrorTracking
    class StackTracesController < Projects::ErrorTracking::BaseController
      respond_to :json

      before_action :authorize_read_sentry_issue!, :set_polling_interval

      def index
        result = fetch_latest_event_issue

        if result[:status] == :success
          result_with_syntax_highlight = Gitlab::ErrorTracking::StackTraceHighlightDecorator.decorate(
            result[:latest_event]
          )

          render json: { error: serialize_error_event(result_with_syntax_highlight) }
        else
          render json: { message: result[:message] }, status: result.fetch(:http_status, :bad_request)
        end
      end

      private

      def fetch_latest_event_issue
        ::ErrorTracking::IssueLatestEventService
          .new(project, current_user, issue_id: params[:issue_id])
          .execute
      end

      def serialize_error_event(event)
        ::ErrorTracking::ErrorEventSerializer
          .new(project: project, user: current_user)
          .represent(event)
      end
    end
  end
end
