# frozen_string_literal: true

module EE
  module Milestones
    module UpdateService
      extend ::Gitlab::Utils::Override

      override :execute
      # rubocop: disable CodeReuse/ActiveRecord
      def execute(milestone)
        super

        if dates_changed?(milestone)
          ::Epic.update_start_and_due_dates(
            ::Epic.joins(:issues).where(issues: { milestone_id: milestone.id })
          )
        end

        milestone
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def dates_changed?(milestone)
        changes = milestone.previous_changes
        changes.include?(:start_date) || changes.include?(:due_date)
      end
    end
  end
end
