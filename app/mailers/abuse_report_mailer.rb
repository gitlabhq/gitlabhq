# frozen_string_literal: true

class AbuseReportMailer < ApplicationMailer
  layout 'empty_mailer'

  helper EmailsHelper

  def notify(abuse_report_id)
    return unless deliverable?

    @abuse_report = AbuseReport.find(abuse_report_id)

    mail_with_locale(
      to: Gitlab::CurrentSettings.abuse_notification_email,
      subject: "#{@abuse_report.user.name} (#{@abuse_report.user.username}) was reported for abuse"
    )
  end

  private

  def deliverable?
    Gitlab::CurrentSettings.abuse_notification_email.present?
  end
end
