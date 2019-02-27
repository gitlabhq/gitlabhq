# frozen_string_literal: true

module Projects
  class DailyStatisticsFinder
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def fetches
      ProjectDailyStatistic.of_project(project)
        .of_last_30_days
        .sorted_by_date_desc
    end

    def total_fetch_count
      fetches.sum_fetch_count
    end
  end
end
