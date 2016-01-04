class AbuseReportsController < ApplicationController
  def new
    @abuse_report = AbuseReport.new
    @abuse_report.user_id = params[:user_id]
  end

  def create
    @abuse_report = AbuseReport.new(report_params)
    @abuse_report.reporter = current_user

    if @abuse_report.save
      if current_application_settings.admin_notification_email.present?
        AbuseReportMailer.notify(@abuse_report.id).deliver_later
      end

      message = "Thank you for your report. A GitLab administrator will look into it shortly."
      redirect_to @abuse_report.user, notice: message
    else
      render :new
    end
  end

  private

  def report_params
    params.require(:abuse_report).permit(%i(
      message
      user_id
    ))
  end
end
