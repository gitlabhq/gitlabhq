# frozen_string_literal: true

class Admin::AbuseReportsController < Admin::ApplicationController
  feature_category :insider_threat

  before_action :set_status_param, only: :index, if: -> { Feature.enabled?(:abuse_reports_list) }

  def index
    @abuse_reports = AbuseReportsFinder.new(params).execute
  end

  def show
    @abuse_report = AbuseReport.find(params[:id])
  end

  def destroy
    abuse_report = AbuseReport.find(params[:id])

    abuse_report.remove_user(deleted_by: current_user) if params[:remove_user]
    abuse_report.destroy

    head :ok
  end

  private

  def set_status_param
    params[:status] ||= 'open'
  end
end
