class Admin::AbuseReportsController < Admin::ApplicationController
  def index
    @abuse_reports = AbuseReport.order(id: :desc).page(params[:page])
  end

  def destroy
    AbuseReport.find(params[:id]).destroy

    redirect_to admin_abuse_reports_path, notice: 'Report was removed'
  end
end
