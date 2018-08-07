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

        data = ::UpdateEpicDatesFromMilestones::Epics::DateSourcingMilestonesFinder.new(epics.first.id)

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

  module Epics
    class DateSourcingMilestonesFinder
      include Gitlab::Utils::StrongMemoize

      FIELDS = [:id, :start_date, :due_date].freeze
      ID_INDEX = FIELDS.index(:id)
      START_DATE_INDEX = FIELDS.index(:start_date)
      DUE_DATE_INDEX = FIELDS.index(:due_date)

      def initialize(epic_id)
        @epic_id = epic_id
      end

      def execute
        strong_memoize(:execute) do
          Milestone.joins(issues: :epic_issue).where(epic_issues: { epic_id: epic_id }).joins(
            <<~SQL
            INNER JOIN (
              SELECT MIN(milestones.start_date) AS start_date, MAX(milestones.due_date) AS due_date
              FROM milestones
              INNER JOIN issues ON issues.milestone_id = milestones.id
              INNER JOIN epic_issues ON epic_issues.issue_id = issues.id
              WHERE epic_issues.epic_id = #{epic_id}
            ) inner_results ON (inner_results.start_date = milestones.start_date OR inner_results.due_date = milestones.due_date)
          SQL
          ).pluck(*FIELDS)
        end
      end

      def start_date
        start_date_sourcing_milestone&.slice(START_DATE_INDEX)
      end

      def start_date_sourcing_milestone_id
        start_date_sourcing_milestone&.slice(ID_INDEX)
      end

      def due_date
        due_date_sourcing_milestone&.slice(DUE_DATE_INDEX)
      end

      def due_date_sourcing_milestone_id
        due_date_sourcing_milestone&.slice(ID_INDEX)
      end

      private

      attr_reader :epic_id

      def start_date_sourcing_milestone
        @start_date_sourcing_milestone ||= execute
          .reject { |row| row[START_DATE_INDEX].nil? }
          .min_by { |row| row[START_DATE_INDEX] }
      end

      def due_date_sourcing_milestone
        @due_date_sourcing_milestone ||= execute
          .reject { |row| row[DUE_DATE_INDEX].nil? }
          .max_by { |row| row[DUE_DATE_INDEX] }
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
