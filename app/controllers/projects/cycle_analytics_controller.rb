class Projects::CycleAnalyticsController < Projects::ApplicationController
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper

  before_action :authorize_read_cycle_analytics!

  def show
    @cycle_analytics = ::CycleAnalytics.new(@project, from: parse_start_date)

    respond_to do |format|
      format.html
      format.json { render json: cycle_analytics_json }
    end
  end

  private

  def parse_start_date
    case cycle_analytics_params[:start_date]
    when '30' then 30.days.ago
    when '90' then 90.days.ago
    else 90.days.ago
    end
  end

  def cycle_analytics_params
    return {} unless params[:cycle_analytics].present?

    { start_date: params[:cycle_analytics][:start_date] }
  end

  def cycle_analytics_json
    cycle_analytics_view_data = [[:issue, "Issue", "Time before an issue gets scheduled"],
                                 [:plan, "Plan", "Time before an issue starts implementation"],
                                 [:code, "Code", "Time until first merge request"],
                                 [:test, "Test", "Total test time for all commits/merges"],
                                 [:review, "Review", "Time between merge request creation and merge/close"],
                                 [:staging, "Staging", "From merge request merge until deploy to production"],
                                 [:production, "Production", "From issue creation until deploy to production"]]

    stats = cycle_analytics_view_data.reduce([]) do |stats, (stage_method, stage_text, stage_description)|
      value = @cycle_analytics.send(stage_method).presence

      stats << {
        title: stage_text,
        description: stage_description,
        value: value && !value.zero? ? distance_of_time_in_words(value) : nil
      }
      stats
    end

    issues = @cycle_analytics.summary.new_issues
    commits = @cycle_analytics.summary.commits
    deploys = @cycle_analytics.summary.deploys

    summary = [
      { title: "New Issue".pluralize(issues), value: issues },
      { title: "Commit".pluralize(commits), value: commits },
      { title: "Deploy".pluralize(deploys), value: deploys }
    ]

    {
      summary: summary,
      stats: stats
    }
  end
end
