class AbuseReportsController < ApplicationController
  def new
    @abuse_report = AbuseReport.new
    @abuse_report.user_id = params[:user_id]
    @ref_url = params.fetch(:ref_url, '')
  end

  def create
    @abuse_report = AbuseReport.new(report_params)
    @abuse_report.reporter = current_user

    if @abuse_report.save
      @abuse_report.notify

      message = "感谢您的报告。GitLab 管理员会尽快处理。"
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
