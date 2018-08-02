# frozen_string_literal: true

class UpdateEpicDatesFromMilestones < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Epic < ActiveRecord::Base
    self.table_name = 'epics'
    include EachBatch

    has_many :epic_issues
    has_many :issues, through: :epic_issues

    def self.update_dates(epics)
      groups = epics.includes(:issues).group_by do |epic|
        milestone_ids = epic.issues.map(&:milestone_id)
        milestone_ids.compact!
        milestone_ids.uniq!
        milestone_ids
      end

      groups.each do |milestone_ids, epics|
        next if milestone_ids.empty?

        data = epics.first.fetch_milestone_date_data

        self.where(id: epics.map(&:id)).update_all(
          [
            %{
                start_date = CASE WHEN start_date_is_fixed = true THEN start_date ELSE ? END,
                start_date_sourcing_milestone_id = ?,
                end_date = CASE WHEN due_date_is_fixed = true THEN end_date ELSE ? END,
                due_date_sourcing_milestone_id = ?
              },
            data[:start_date],
            data[:start_date_sourcing_milestone_id],
            data[:due_date],
            data[:due_date_sourcing_milestone_id]
          ]
        )
      end
    end

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
      SQL

      db_results = ActiveRecord::Base.connection.select_all(sql).to_a

      results = {}
      db_results
        .reject { |row| row['start_date'].nil? }
        .min_by { |row| row['start_date'] }&.tap do |row|
        results[:start_date] = row['start_date']
        results[:start_date_sourcing_milestone_id] = row['id']
      end
      db_results
        .reject { |row| row['due_date'].nil? }
        .max_by { |row| row['due_date'] }&.tap do |row|
        results[:due_date] = row['due_date']
        results[:due_date_sourcing_milestone_id] = row['id']
      end
      results
    end
  end

  def up
    Epic.joins(:issues).where('issues.milestone_id IS NOT NULL').each_batch do |epics|
      Epic.update_dates(epics)
    end
  end

  def down
    # NOOP
  end
end
