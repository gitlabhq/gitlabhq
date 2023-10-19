# frozen_string_literal: true

module ResourceEvents
  module AbuseReportEventsHelper
    def success_message_for_action(action)
      case action
      when 'ban_user'
        s_('AbuseReportEvent|Successfully banned the user')
      when 'block_user'
        s_('AbuseReportEvent|Successfully blocked the user')
      when 'delete_user'
        s_('AbuseReportEvent|Successfully scheduled the user for deletion')
      when 'trust_user'
        s_('AbuseReportEvent|Successfully trusted the user')
      when 'close_report'
        s_('AbuseReportEvent|Successfully closed the report')
      when 'ban_user_and_close_report'
        s_('AbuseReportEvent|Successfully banned the user and closed the report')
      when 'block_user_and_close_report'
        s_('AbuseReportEvent|Successfully blocked the user and closed the report')
      when 'delete_user_and_close_report'
        s_('AbuseReportEvent|Successfully scheduled the user for deletion and closed the report')
      when 'trust_user_and_close_report'
        s_('AbuseReportEvent|Successfully trusted the user and closed the report')
      end
    end
  end
end
