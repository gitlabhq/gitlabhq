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

    def self.update_start_and_due_dates(epics)
      groups = epics.includes(:issues).group_by do |epic|
        milestone_ids = epic.issues.map(&:milestone_id)
        milestone_ids.compact!
        milestone_ids.uniq!
        milestone_ids
      end

      groups.each do |milestone_ids, epics|
        next if milestone_ids.empty?

        data = ::Epics::DateSourcingMilestonesFinder.execute(epics.first.id)

        self.where(id: epics.map(&:id)).update_all(
          [
            %{
              start_date = CASE WHEN start_date_is_fixed = true THEN start_date ELSE ? END,
              start_date_sourcing_milestone_id = ?,
              end_date = CASE WHEN due_date_is_fixed = true THEN end_date ELSE ? END,
              due_date_sourcing_milestone_id = ?
            },
            data.start_date,
            data.start_date_sourcing_milestone_id,
            data.due_date,
            data.due_date_sourcing_milestone_id
          ]
        )
      end
    end
  end

  def up
    # Fill fixed date columns for remaining eligible records touched after regular migration is run
    # (20180711014026_update_date_columns_on_epics) but before new app code takes effect.
    Epic.where(start_date_is_fixed: nil).where.not(start_date: nil).each_batch do |batch|
      batch.update_all('start_date_is_fixed = true, start_date_fixed = start_date')
    end
    Epic.where(due_date_is_fixed: nil).where.not(end_date: nil).each_batch do |batch|
      batch.update_all('due_date_is_fixed = true, due_date_fixed = end_date')
    end

    Epic.joins(:issues).where('issues.milestone_id IS NOT NULL').each_batch do |epics|
      Epic.update_start_and_due_dates(epics)
    end
  end

  def down
    # NOOP
  end
end
