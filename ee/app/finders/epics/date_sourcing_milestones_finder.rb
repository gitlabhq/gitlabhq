module Epics
  class DateSourcingMilestonesFinder
    def self.execute(epic_id)
      sql = <<~SQL
        SELECT milestones.id, milestones.start_date, milestones.due_date FROM milestones
        INNER JOIN issues ON issues.milestone_id = milestones.id
        INNER JOIN epic_issues ON epic_issues.issue_id = issues.id
        INNER JOIN (
          SELECT MIN(milestones.start_date) AS start_date, MAX(milestones.due_date) AS due_date
          FROM milestones
          INNER JOIN issues ON issues.milestone_id = milestones.id
          INNER JOIN epic_issues ON epic_issues.issue_id = issues.id
          WHERE epic_issues.epic_id = #{epic_id}
        ) inner_results ON (inner_results.start_date = milestones.start_date OR inner_results.due_date = milestones.due_date)
        WHERE epic_issues.epic_id = #{epic_id}
      SQL

      new(ActiveRecord::Base.connection.select_all(sql).to_a)
    end

    def initialize(results)
      @results = results
    end

    def start_date
      cast_as_date(start_date_sourcing_milestone&.fetch('start_date', nil))
    end

    def start_date_sourcing_milestone_id
      cast_as_id(start_date_sourcing_milestone&.fetch('id', nil))
    end

    def due_date
      cast_as_date(due_date_sourcing_milestone&.fetch('due_date', nil))
    end

    def due_date_sourcing_milestone_id
      cast_as_id(due_date_sourcing_milestone&.fetch('id', nil))
    end

    private

    attr_reader :results

    def start_date_sourcing_milestone
      @start_date_sourcing_milestone ||= results
        .reject { |row| row['start_date'].nil? }
        .min_by { |row| row['start_date'] }
    end

    def due_date_sourcing_milestone
      @due_date_sourcing_milestone ||= results
        .reject { |row| row['due_date'].nil? }
        .max_by { |row| row['due_date'] }
    end

    def cast_as_date(result)
      if result
        Date.strptime(result, '%Y-%m-%d')
      else
        result
      end
    end

    def cast_as_id(result)
      if result
        result.to_i
      else
        result
      end
    end
  end
end
