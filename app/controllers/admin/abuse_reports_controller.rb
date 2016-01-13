class Admin::AbuseReportsController < Admin::ApplicationController
  def index
    @abuse_reports = AbuseReport.order(id: :desc).page(params[:page])
  end

  def destroy
    abuse_report = AbuseReport.find(params[:id])

    abuse_report.remove_user if params[:remove_user]
    abuse_report.destroy

    render nothing: true
  end
end
