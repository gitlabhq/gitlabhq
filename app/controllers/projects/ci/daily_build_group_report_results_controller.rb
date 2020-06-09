# frozen_string_literal: true

class Projects::Ci::DailyBuildGroupReportResultsController < Projects::ApplicationController
  include Gitlab::Utils::StrongMemoize

  MAX_ITEMS = 1000
  REPORT_WINDOW = 90.days

  before_action :validate_feature_flag!
  before_action :authorize_read_build_report_results!
  before_action :validate_param_type!

  def index
    respond_to do |format|
      format.csv { send_data(render_csv(report_results), type: 'text/csv; charset=utf-8') }
      format.json { render json: render_json(report_results) }
    end
  end

  private

  def validate_feature_flag!
    render_404 unless Feature.enabled?(:ci_download_daily_code_coverage, project, default_enabled: true)
  end

  def validate_param_type!
    respond_422 unless allowed_param_types.include?(param_type)
  end

  def render_csv(collection)
    CsvBuilders::SingleBatch.new(
      collection,
      {
        date: 'date',
        group_name: 'group_name',
        param_type => -> (record) { record.data[param_type] }
      }
    ).render
  end

  def render_json(collection)
    Ci::DailyBuildGroupReportResultSerializer.new.represent(collection, param_type: param_type)
  end

  def report_results
    Ci::DailyBuildGroupReportResultsFinder.new(finder_params).execute
  end

  def finder_params
    {
      current_user: current_user,
      project: project,
      ref_path: params.require(:ref_path),
      start_date: start_date,
      end_date: end_date,
      limit: MAX_ITEMS
    }
  end

  def start_date
    strong_memoize(:start_date) do
      start_date = Date.parse(params.require(:start_date))

      # The start_date cannot be older than `end_date - 90 days`
      [start_date, end_date - REPORT_WINDOW].max
    end
  end

  def end_date
    strong_memoize(:end_date) do
      Date.parse(params.require(:end_date))
    end
  end

  def allowed_param_types
    Ci::DailyBuildGroupReportResult::PARAM_TYPES
  end

  def param_type
    params.require(:param_type)
  end
end
