# frozen_string_literal: true

module EE
  module Milestones
    module UpdateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(milestone)
        super

        if milestone.previous_changes.key?(:start_date) || milestone.previous_changes.key?(:due_date)
          update_epics(milestone)
        end

        milestone
      end

      private

      def update_epics(milestone)
        groups = ::Epic.joins(:issues).includes(:issues).where(issues: { milestone_id: milestone.id }).group_by do |epic|
          milestone_ids = epic.issues.map(&:milestone_id)
          milestone_ids.compact!
          milestone_ids.uniq!
          milestone_ids
        end

        groups.each do |milestone_ids, epics|
          data = epics.first.fetch_milestone_date_data

          ::Epic.where(id: epics.map(&:id)).update_all(
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
    end
  end
end
