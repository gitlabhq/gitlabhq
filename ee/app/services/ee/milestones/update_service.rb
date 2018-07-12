module EE
  module Milestones
    module UpdateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(milestone)
        super

        milestone.issues.includes(epic: :group).each do |issue|
          if issue.epic
            issue.epic.update_dates
          end
        end

        milestone
      end
    end
  end
end
