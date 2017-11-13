module Emails
  module CsvExport
    def issues_csv_email(user, project, csv_data, export_status)
      @project = project
      @issues_count = export_status.fetch(:rows_expected)
      @written_count = export_status.fetch(:rows_written)
      @truncated = export_status.fetch(:truncated)

      filename = "#{project.full_path.parameterize}_issues_#{Date.today.iso8601}.csv"
      attachments[filename] = { content: csv_data, mime_type: 'text/csv' }
      mail(to: user.notification_email, subject: subject("Exported issues")) do |format|
        format.html { render layout: 'mailer' }
        format.text { render layout: 'mailer' }
      end
    end
  end
end
