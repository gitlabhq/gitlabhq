# frozen_string_literal: true

class Admin::AbuseReportsController < Admin::ApplicationController
  feature_category :insider_threat

  before_action :set_status_param, only: :index
  before_action :find_abuse_report, only: [:show, :moderate_user, :update, :destroy]
  before_action only: :show do
    push_frontend_feature_flag(:abuse_report_labels)
    push_frontend_feature_flag(:abuse_report_notes)
  end

  def index
    @abuse_reports = AbuseReportsFinder.new(permitted_index_params).execute
  end

  def show; end

  def update
    response = Admin::AbuseReports::UpdateService.new(@abuse_report, current_user, permitted_params).execute

    if response.success?
      head :ok
    else
      render json: { message: response.message }, status: :unprocessable_entity
    end
  end

  def moderate_user
    response = Admin::AbuseReports::ModerateUserService.new(@abuse_report, current_user, permitted_params).execute

    if response.success?
      render json: { message: response.message }
    else
      render json: { message: response.message }, status: :unprocessable_entity
    end
  end

  def destroy
    @abuse_report.remove_user(deleted_by: current_user) if params.permit(:remove_user)[:remove_user]
    @abuse_report.destroy

    head :ok
  end

  private

  def find_abuse_report
    @abuse_report = AbuseReport.find(params.permit(:id)[:id])
  end

  def set_status_param
    params[:status] ||= 'open' # rubocop:disable Rails/StrongParams -- This is setting a default value if none is present
  end

  def permitted_params
    params.permit(:user_action, :close, :reason, :comment, { label_ids: [] })
  end

  def permitted_index_params
    params.permit(:page, :status, :category, :user, :reporter, :sort)
  end
end
