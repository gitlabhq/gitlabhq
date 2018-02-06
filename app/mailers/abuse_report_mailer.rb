class AbuseReportMailer < BaseMailer
  def notify(abuse_report_id)
    return unless deliverable?

    @abuse_report = AbuseReport.find(abuse_report_id)

    mail(
      to:       Gitlab::CurrentSettings.admin_notification_email,
      subject:  "#{@abuse_report.user.name} (#{@abuse_report.user.username}) was reported for abuse"
    )
  end

  private

  def deliverable?
    Gitlab::CurrentSettings.admin_notification_email.present?
  end
end
