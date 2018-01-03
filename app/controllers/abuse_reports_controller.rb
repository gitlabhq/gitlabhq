class AbuseReportsController < ApplicationController
  before_action :set_user, only: [:new]

  def new
    @abuse_report = AbuseReport.new
    @abuse_report.user_id = @user.id
    @ref_url = params.fetch(:ref_url, '')
  end

  def create
    @abuse_report = AbuseReport.new(report_params)
    @abuse_report.reporter = current_user

    if @abuse_report.save
      @abuse_report.notify

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

  def set_user
    @user = User.find_by(id: params[:user_id])

    if @user.nil?
      redirect_to root_path, alert: "Cannot create the abuse report. The user has been deleted."
    elsif @user.blocked?
      redirect_to @user, alert: "Cannot create the abuse report. This user has been blocked."
    end
  end
end
