module CycleAnalyticsHelper
  include ActionView::Helpers::DateHelper

  def cycle_analytics_json(cycle_analytics)
    cycle_analytics_view_data = [[:issue, "Issue", "Time before an issue gets scheduled"],
                                 [:plan, "Plan", "Time before an issue starts implementation"],
                                 [:code, "Code", "Time until first merge request"],
                                 [:test, "Test", "Total test time for all commits/merges"],
                                 [:review, "Review", "Time between MR creation and merge/close"],
                                 [:staging, "Staging", "From MR merge until deploy to production"],
                                 [:production, "Production", "From issue creation until deploy to production"]]

    stats = cycle_analytics_view_data.reduce({}) do |hash, (stage_method, stage_text, stage_description)|
      hash[stage_method] = {
        title: stage_text,
        description: stage_description,
        value: distance_of_time_in_words(cycle_analytics.send(stage_method))
      }
      hash
    end

    { stats: stats }
  end
end
