# frozen_string_literal: true

class AbuseReportsController < ApplicationController
  before_action :set_user, only: [:add_category]

  feature_category :insider_threat

  def add_category
    @abuse_report = AbuseReport.new(
      user_id: @user.id,
      category: report_params[:category],
      reported_from_url: report_params[:reported_from_url]
    )

    Gitlab::Tracking.event(
      'ReportAbuse',
      'select_abuse_category',
      property: report_params[:category],
      user: @user
    )

    render :new
  end

  def create
    @abuse_report = AbuseReport.new(report_params)
    @abuse_report.reporter = current_user

    if @abuse_report.save
      @abuse_report.notify

      Gitlab::Tracking.event(
        'ReportAbuse',
        'submit_form',
        property: @abuse_report.category,
        user: @abuse_report.user
      )

      message = _("Thank you for your report. A GitLab administrator will look into it shortly.")
      redirect_to root_path, notice: message
    elsif report_params[:user_id].present?
      render :new
    else
      redirect_to root_path,
        alert: _("Cannot create the abuse report. The reported user was invalid. Please try again or contact support.")
    end
  end

  private

  def report_params
    params.require(:abuse_report).permit(:message, :user_id, :category, :reported_from_url, :screenshot,
      links_to_spam: [])
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def set_user
    @user = User.find_by(id: params.permit(:user_id)[:user_id])

    if @user.nil?
      redirect_to root_path, alert: _("Cannot create the abuse report. The user has been deleted.")
    elsif @user.banned?
      redirect_to @user, alert: _("Cannot create the abuse report. This user has been banned.")
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
