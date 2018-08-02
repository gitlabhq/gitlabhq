# frozen_string_literal: true

module EE
  module Milestones
    module UpdateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(milestone)
        super

        if milestone.previous_changes.key?(:start_date) || milestone.previous_changes.key?(:due_date)
          ::Epic.update_dates(
            ::Epic.joins(:issues).where(issues: { milestone_id: milestone.id })
          )
        end

        milestone
      end
    end
  end
end
