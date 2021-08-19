# frozen_string_literal: true

module Projects
  class FetchStatisticsIncrementService
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute
      increment_fetch_count_sql = <<~SQL
        INSERT INTO #{table_name} (project_id, date, fetch_count)
        VALUES (#{project.id}, '#{Date.today}', 1)
        ON CONFLICT (project_id, date) DO UPDATE SET fetch_count = #{table_name}.fetch_count + 1
      SQL

      ProjectDailyStatistic.connection.execute(increment_fetch_count_sql)
    end

    private

    def table_name
      ProjectDailyStatistic.table_name
    end
  end
end
