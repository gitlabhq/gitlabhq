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
    @reports = reports.with_labels if Feature.enabled?(:abuse_report_labels)

    filter_reports
    aggregate_reports
    sort_reports

    reports.with_users.page(params[:page])
  end

  private

  def filter_reports
    filter_by_status
    filter_by_user
    filter_by_reporter
    filter_by_category
  end

  def filter_by_status
    return unless params[:status].present?

    case status_filter
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
    # let sub_query in aggregate_reports do the sorting if sorting by number of reports
    return if sort_key.in?(SORT_BY_COUNT)

    @reports = @reports.order_by(sort_key)
  end

  def find_user_id(username)
    User.by_username(username).pick(:id)
  end

  def aggregate_reports
    if status_open?
      sort_by_count = sort_key.in?(SORT_BY_COUNT)
      @reports = @reports.aggregated_by_user_and_category(sort_by_count)
    end

    @reports
  end

  def status_filter
    @status_filter ||=
      if params[:status].in?(AbuseReport.statuses.keys)
        params[:status]
      else
        STATUS_OPEN
      end
  end

  def status_open?
    return false if params[:status].blank?

    status_filter == STATUS_OPEN
  end
end
