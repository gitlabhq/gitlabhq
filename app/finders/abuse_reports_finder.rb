# frozen_string_literal: true

class AbuseReportsFinder
  attr_reader :params, :reports

  DEFAULT_STATUS_FILTER = 'open'
  DEFAULT_SORT = 'created_at_desc'
  ALLOWED_SORT = [DEFAULT_SORT, *%w[created_at_asc updated_at_desc updated_at_asc]].freeze

  def initialize(params = {})
    @params = params
    @reports = AbuseReport.all
  end

  def execute
    filter_reports
    sort_reports

    reports.with_users.page(params[:page])
  end

  private

  def filter_reports
    filter_by_user_id

    filter_by_user
    filter_by_reporter
    filter_by_status
    filter_by_category
  end

  def filter_by_status
    return unless Feature.enabled?(:abuse_reports_list)
    return unless params[:status].present?

    status = params[:status]
    status = DEFAULT_STATUS_FILTER unless status.in?(AbuseReport.statuses.keys)

    case status
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

    user_id = find_user_id(params[:user])
    return unless user_id

    @reports = @reports.by_user_id(user_id)
  end

  def filter_by_reporter
    return unless params[:reporter].present?

    user_id = find_user_id(params[:reporter])
    return unless user_id

    @reports = @reports.by_reporter_id(user_id)
  end

  def filter_by_user_id
    return unless params[:user_id].present?

    @reports = @reports.by_user_id(params[:user_id])
  end

  def sort_reports
    if Feature.disabled?(:abuse_reports_list)
      @reports = @reports.with_order_id_desc
      return
    end

    sort_by = params[:sort]
    sort_by = DEFAULT_SORT unless sort_by.in?(ALLOWED_SORT)

    @reports = @reports.order_by(sort_by)
  end

  def find_user_id(username)
    User.by_username(username).pick(:id)
  end
end
