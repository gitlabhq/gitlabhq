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
        AbuseReportMailer.delay.notify(@abuse_report.id)
      end

      message = "Thank you for your report. A GitLab administrator will look into it shortly."
      redirect_to root_path, notice: message
    else
      render :new
    end
  end

  private

  def report_params
    params.require(:abuse_report).permit(:user_id, :message)
  end
end
