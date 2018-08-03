# frozen_string_literal: true

module EE
  module Issues
    module UpdateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(issue)
        result = super

        if issue.previous_changes.include?(:milestone_id) && issue.epic
          issue.epic.update_dates
        end

        result
      end
    end
  end
end
