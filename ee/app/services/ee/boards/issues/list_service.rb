module EE
  module Boards
    module Issues
      module ListService
        extend ::Gitlab::Utils::Override

        override :filter
        def filter(issues)
          issues = without_board_assignees(issues) unless list&.movable? || list&.closed?

          return super unless list&.assignee?

          with_assignee(super)
        end

        override :issues_label_links
        def issues_label_links
          if has_valid_milestone?
            super.where("issues.milestone_id = ?", board.milestone_id)
          else
            super
          end
        end

        private

        def board_assignee_ids
          @board_assignee_ids ||=
            if parent.feature_available?(:board_assignee_lists)
              board.lists.movable.pluck(:user_id).compact
            else
              []
            end
        end

        def without_board_assignees(issues)
          return issues unless board_assignee_ids.any?

          issues.where.not(id: issues.joins(:assignees).where(users: { id: board_assignee_ids }))
        end

        def with_assignee(issues)
          issues.assigned_to(list.user)
        end

        # Prevent filtering by milestone stubs
        # like Milestone::Upcoming, Milestone::Started etc
        def has_valid_milestone?
          return false unless board.milestone

          !::Milestone.predefined?(board.milestone)
        end
      end
    end
  end
end
