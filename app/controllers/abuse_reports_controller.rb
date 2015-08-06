class AbuseReportsController < ApplicationController
  def new
    @abuse_report = AbuseReport.new
    @abuse_report.user_id = params[:user_id]
  end

  def create
    @abuse_report = AbuseReport.new(report_params)
    @abuse_report.reporter = current_user

    if @abuse_report.save
      redirect_to root_path, notice: 'Thank you for report. GitLab administrator will be able to see it'
    else
      render :new
    end
  end

  private

  def report_params
    params.require(:abuse_report).permit(:user_id, :message)
  end
end
