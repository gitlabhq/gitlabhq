# frozen_string_literal: true

module EE
  module Milestones
    module UpdateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(milestone)
        super

        if dates_changed?(milestone)
          ::Epic.update_dates(
            ::Epic.joins(:issues).where(issues: { milestone_id: milestone.id })
          )
        end

        milestone
      end

      private

      def dates_changed?(milestone)
        changes = milestone.previous_changes
        changes.include?(:start_date) || changes.include?(:due_date)
      end
    end
  end
end
