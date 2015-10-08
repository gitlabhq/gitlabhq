class AbuseReportMailer < BaseMailer

  def notify(abuse_report, to_email)
    @abuse_report = abuse_report

    mail(to: to_email, subject: "[Gitlab] Abuse report filed for `#{@abuse_report.user.username}`")
  end
end
