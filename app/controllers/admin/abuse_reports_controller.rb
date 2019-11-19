# frozen_string_literal: true

class Admin::AbuseReportsController < Admin::ApplicationController
  def index
    @abuse_reports = AbuseReportsFinder.new(params).execute
  end

  def destroy
    abuse_report = AbuseReport.find(params[:id])

    abuse_report.remove_user(deleted_by: current_user) if params[:remove_user]
    abuse_report.destroy

    head :ok
  end
end
