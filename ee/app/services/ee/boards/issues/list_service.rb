module EE
  module Boards
    module Issues
      module ListService
        extend ::Gitlab::Utils::Override

        override :filter
        def filter(issues)
          unless list&.movable? || list&.closed?
            issues = without_assignees_from_lists(issues)
            issues = without_milestones_from_lists(issues)
          end

          case list&.list_type
          when 'assignee'
            with_assignee(super)
          when 'milestone'
            with_milestone(super)
          else
            super
          end
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

        def all_assignee_lists
          if parent.feature_available?(:board_assignee_lists)
            board.lists.assignee.where.not(user_id: nil)
          else
            ::List.none
          end
        end

        def all_milestone_lists
          if parent.feature_available?(:board_milestone_lists)
            board.lists.milestone.where.not(milestone_id: nil)
          else
            ::List.none
          end
        end

        def without_assignees_from_lists(issues)
          return issues if all_assignee_lists.empty?

          issues
            .where.not(id: issues.joins(:assignees).where(users: { id: all_assignee_lists.select(:user_id) }))
        end

        override :metadata_fields
        def metadata_fields
          super.merge(total_weight: 'COALESCE(SUM(weight), 0)')
        end

        def without_milestones_from_lists(issues)
          return issues if all_milestone_lists.empty?

          issues.where("milestone_id NOT IN (?) OR milestone_id IS NULL",
                       all_milestone_lists.select(:milestone_id))
        end

        def with_assignee(issues)
          issues.assigned_to(list.user)
        end

        def with_milestone(issues)
          issues.where(milestone_id: list.milestone_id)
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
