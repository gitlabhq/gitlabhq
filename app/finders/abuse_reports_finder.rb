# frozen_string_literal: true

class AbuseReportsFinder
  attr_reader :params

  def initialize(params = {})
    @params = params
  end

  def execute
    reports = AbuseReport.all
    reports = reports.by_user(params[:user_id]) if params[:user_id].present?

    reports.with_order_id_desc
      .with_users
      .page(params[:page])
  end
end
