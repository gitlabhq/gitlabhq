class Admin::AbuseReportsController < Admin::ApplicationController
  # rubocop: disable CodeReuse/ActiveRecord
  def index
    @abuse_reports = AbuseReport.order(id: :desc).page(params[:page])
    @abuse_reports.includes(:reporter, :user)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def destroy
    abuse_report = AbuseReport.find(params[:id])

    abuse_report.remove_user(deleted_by: current_user) if params[:remove_user]
    abuse_report.destroy

    head :ok
  end
end
