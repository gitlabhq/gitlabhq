class AbuseReportMailer < BaseMailer
  include Gitlab::CurrentSettings

  def notify(abuse_report_id)
    @abuse_report = AbuseReport.find(abuse_report_id)

    mail(
      to:       current_application_settings.admin_notification_email, 
      subject:  "#{@abuse_report.user.name} (#{@abuse_report.user.username}) was reported for abuse"
    )
  end
end
