# frozen_string_literal: true

module Projects
  class FetchStatisticsIncrementService
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute
      ProjectDailyStatistic
      .find_or_create_project_daily_statistic(project.id, Date.today)
      .increment_fetch_count(1)
    end

    private

    def table_name
      ProjectDailyStatistic.table_name
    end
  end
end
