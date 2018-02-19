module EE
  module Issues
    module MoveService
      def update_old_issue
        rewrite_epic_issue
        super
      end

      private

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def rewrite_epic_issue
        return unless epic_issue = @old_issue.epic_issue
        return unless can?(current_user, :update_epic, epic_issue.epic.group)

        epic_issue.update(issue_id: @new_issue.id)
        @old_issue.reload
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
