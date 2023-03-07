# frozen_string_literal: true

class AbuseReportsFinder
  attr_reader :params, :reports

  def initialize(params = {})
    @params = params
    @reports = AbuseReport.all
  end

  def execute
    filter_reports

    reports.with_order_id_desc
      .with_users
      .page(params[:page])
  end

  private

  def filter_reports
    filter_by_user_id

    filter_by_user
    filter_by_status
    filter_by_category
  end

  def filter_by_status
    return unless params[:status].present?

    case params[:status]
    when 'open'
      @reports = @reports.open
    when 'closed'
      @reports = @reports.closed
    end
  end

  def filter_by_category
    return unless params[:category].present?

    @reports = @reports.by_category(params[:category])
  end

  def filter_by_user
    return unless params[:user].present?

    user_id = User.by_username(params[:user]).pick(:id)
    return unless user_id

    @reports = @reports.by_user_id(user_id)
  end

  def filter_by_user_id
    return unless params[:user_id].present?

    @reports = @reports.by_user_id(params[:user_id])
  end
end
