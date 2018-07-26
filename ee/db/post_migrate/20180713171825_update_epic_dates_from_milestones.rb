class UpdateEpicDatesFromMilestones < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Epic < ActiveRecord::Base
    self.table_name = 'epics'
    include EachBatch

    def update_dates
      milestone_data = fetch_milestone_date_data

      self.start_date = start_date_is_fixed? ? start_date_fixed : milestone_data[:start_date]
      self.start_date_sourcing_milestone_id = milestone_data[:start_date_sourcing_milestone_id]
      self.due_date = due_date_is_fixed? ? due_date_fixed : milestone_data[:due_date]
      self.due_date_sourcing_milestone_id = milestone_data[:due_date_sourcing_milestone_id]

      save if changed?
    end

    private

    def fetch_milestone_date_data
      sql = <<~SQL
        SELECT milestones.id, milestones.start_date, milestones.due_date FROM milestones
        INNER JOIN issues ON issues.milestone_id = milestones.id
        INNER JOIN epic_issues ON epic_issues.issue_id = issues.id
        INNER JOIN (
          SELECT MIN(milestones.start_date) AS start_date, MAX(milestones.due_date) AS due_date
          FROM milestones
          INNER JOIN issues ON issues.milestone_id = milestones.id
          INNER JOIN epic_issues ON epic_issues.issue_id = issues.id
          WHERE epic_issues.epic_id = #{id}
        ) inner_results ON (inner_results.start_date = milestones.start_date OR inner_results.due_date = milestones.due_date)
        WHERE epic_issues.epic_id = #{id}
        ORDER BY milestones.start_date, milestones.due_date;
      SQL

      db_results = ActiveRecord::Base.connection.select_all(sql).to_a

      results = {}
      db_results.find { |row| row['start_date'] }&.tap do |row|
        results[:start_date] = row['start_date']
        results[:start_date_sourcing_milestone_id] = row['id']
      end
      db_results.reverse.find { |row| row['due_date'] }&.tap do |row|
        results[:due_date] = row['due_date']
        results[:due_date_sourcing_milestone_id] = row['id']
      end
      results
    end
  end

  def up
    Epic.where(start_date: nil).find_each do |epic|
      epic.update_dates
    end
  end

  def down
    # NOOP
  end
end
