module EE
  module Milestones
    module UpdateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(milestone)
        super

        ::Epic.joins(:issues).where(issues: { milestone_id: milestone.id }).each do |epic|
          epic.update_dates
        end

        milestone
      end
    end
  end
end
