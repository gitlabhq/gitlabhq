# frozen_string_literal: true

module Admin
  module AbuseReports
    class ModerateUserService < BaseService
      attr_reader :abuse_report, :params, :current_user, :action

      def initialize(abuse_report, current_user, params)
        @abuse_report = abuse_report
        @current_user = current_user
        @params = params
        @action = determine_action
      end

      def execute
        return ServiceResponse.error(message: 'Admin is required') unless current_user&.can_admin_all_resources?
        return ServiceResponse.error(message: 'Action is required') unless action.present?

        result = perform_action
        if result[:status] == :success
          event = close_report_and_record_event
          ServiceResponse.success(message: event.success_message)
        else
          ServiceResponse.error(message: result[:message])
        end
      end

      private

      def determine_action
        action = params[:user_action]
        if action.in?(ResourceEvents::AbuseReportEvent.actions.keys)
          action.to_sym
        elsif close_report?
          :close_report
        end
      end

      def perform_action
        case action
        when :ban_user then ban_user
        when :block_user then block_user
        when :delete_user then delete_user
        when :close_report then close_report
        when :trust_user then trust_user
        end
      end

      def ban_user
        Users::BanService.new(current_user).execute(abuse_report.user)
      end

      def block_user
        Users::BlockService.new(current_user).execute(abuse_report.user)
      end

      def delete_user
        abuse_report.user.delete_async(deleted_by: current_user)
        success
      end

      def close_report
        return error('Report already closed') if abuse_report.closed?

        close_similar_open_reports
        abuse_report.closed!
        success
      end

      def trust_user
        Users::TrustService.new(current_user).execute(abuse_report.user)
      end

      def close_similar_open_reports
        # admins see the abuse report and other open reports for the same user in one page
        # hence, if the request is to close the report, close other open reports for the same user too
        abuse_report.similar_open_reports_for_user.update_all(status: 'closed')
      end

      def close_report_and_record_event
        event = action

        if close_report? && action != :close_report
          close_report
          event = "#{action}_and_close_report"
        end

        record_event(event)
      end

      def close_report?
        params[:close].to_s == 'true'
      end

      def record_event(action)
        reason = params[:reason]
        unless reason.in?(ResourceEvents::AbuseReportEvent.reasons.keys)
          reason = ResourceEvents::AbuseReportEvent.reasons[:other]
        end

        abuse_report.events.create(action: action, user: current_user, reason: reason, comment: params[:comment])
      end
    end
  end
end
