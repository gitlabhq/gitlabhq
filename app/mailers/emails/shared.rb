# frozen_string_literal: true

module Emails
  module Shared
    def csv_email(user, project, csv_data, export_status, type)
      @project = project
      @count = export_status.fetch(:rows_expected)
      @written_count = export_status.fetch(:rows_written)
      @truncated = export_status.fetch(:truncated)
      @size_limit = ActiveSupport::NumberHelper
        .number_to_human_size(ExportCsv::BaseService::TARGET_FILESIZE)

      filename = "#{project.full_path.parameterize}_#{type}_#{Date.today.iso8601}.csv"
      attachments[filename] = { content: csv_data, mime_type: 'text/csv' }
      email_with_layout(
        to: user.notification_email_for(@project.group),
        subject: subject("Exported #{type.humanize.downcase}"))
    end
  end
end
