# frozen_string_literal: true

class AbuseReportsFinder
  attr_reader :params, :reports

  STATUS_OPEN = 'open'

  DEFAULT_SORT_STATUS_CLOSED = 'created_at_desc'
  ALLOWED_SORT = [DEFAULT_SORT_STATUS_CLOSED, *%w[created_at_asc updated_at_desc updated_at_asc]].freeze

  DEFAULT_SORT_STATUS_OPEN = 'number_of_reports_desc'
  SORT_BY_COUNT = [DEFAULT_SORT_STATUS_OPEN].freeze

  def initialize(params = {})
    @params = params
    @reports = AbuseReport.all
  end

  def execute
    filter_reports
    aggregate_reports
    sort_reports

    reports.with_users.page(params[:page])
  end

  private

  def filter_reports
    if Feature.disabled?(:abuse_reports_list)
      filter_by_user_id
      return
    end

    filter_by_status
    filter_by_user
    filter_by_reporter
    filter_by_category
  end

  def filter_by_user_id
    return unless params[:user_id].present?

    @reports = @reports.by_user_id(params[:user_id])
  end

  def filter_by_status
    return unless params[:status].present?

    status = params[:status]
    status = STATUS_OPEN unless status.in?(AbuseReport.statuses.keys)

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

  def sort_key
    sort_key = params[:sort]

    return sort_key if sort_key.in?(ALLOWED_SORT + SORT_BY_COUNT)
    return DEFAULT_SORT_STATUS_OPEN if status_open?

    DEFAULT_SORT_STATUS_CLOSED
  end

  def sort_reports
    if Feature.disabled?(:abuse_reports_list)
      @reports = @reports.with_order_id_desc
      return
    end

    # let sub_query in aggregate_reports do the sorting if sorting by number of reports
    return if sort_key.in?(SORT_BY_COUNT)

    @reports = @reports.order_by(sort_key)
  end

  def find_user_id(username)
    User.by_username(username).pick(:id)
  end

  def status_open?
    return unless Feature.enabled?(:abuse_reports_list) && params[:status].present?

    status = params[:status]
    status = STATUS_OPEN unless status.in?(AbuseReport.statuses.keys)

    status == STATUS_OPEN
  end

  def aggregate_reports
    if status_open?
      sort_by_count = sort_key.in?(SORT_BY_COUNT)
      @reports = @reports.aggregated_by_user_and_category(sort_by_count)
    end

    @reports
  end
end
