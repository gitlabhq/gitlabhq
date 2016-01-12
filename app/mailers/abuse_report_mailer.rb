class AbuseReportMailer < BaseMailer
  include Gitlab::CurrentSettings

  def notify(abuse_report_id)
    return unless deliverable?

    @abuse_report = AbuseReport.find(abuse_report_id)

    mail(
      to:       current_application_settings.admin_notification_email,
      subject:  "#{@abuse_report.user.name} (#{@abuse_report.user.username}) was reported for abuse"
    )
  end

  private

  def deliverable?
    current_application_settings.admin_notification_email.present?
  end
end
