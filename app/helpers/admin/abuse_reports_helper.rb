# frozen_string_literal: true

module Admin
  module AbuseReportsHelper
    def abuse_reports_list_data(reports)
      {
        abuse_reports_data: {
          categories: AbuseReport.categories.keys,
          reports: Admin::AbuseReportSerializer.new.represent(reports),
          pagination: {
            current_page: reports.current_page,
            per_page: reports.limit_value,
            total_items: reports.total_count
          }
        }.to_json
      }
    end

    def abuse_report_data(report)
      {
        abuse_report_data: Admin::AbuseReportDetailsSerializer.new.represent(report).to_json,
        abuse_reports_list_path: admin_abuse_reports_path
      }
    end
  end
end
