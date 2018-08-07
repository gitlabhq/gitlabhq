module EE
  module Boards
    module Issues
      module MoveService
        extend ::Gitlab::Utils::Override

        override :issue_params
        def issue_params(issue)
          return super unless move_between_lists?

          args = super

          unless both_are_same_type? || !moving_to_list.movable?
            args.delete(:remove_label_ids)
          end

          args.merge(list_movement_args(issue))
        end

        def both_are_list_type?(type)
          return false unless moving_from_list.list_type == type

          both_are_same_type?
        end

        def both_are_same_type?
          moving_from_list.list_type == moving_to_list.list_type
        end

        def list_movement_args(issue)
          assignee_ids = assignee_ids(issue)
          milestone_id = milestone_id(issue)

          {
            assignee_ids: assignee_ids,
            milestone_id: milestone_id
          }
        end

        def milestone_id(issue)
          # We want to nullify the issue milestone.
          return if moving_to_list.backlog?

          # Moving to a list which is not a 'milestone list' will keep
          # the already existent milestone.
          [issue.milestone_id, moving_to_list.milestone_id].compact.last
        end

        def assignee_ids(issue)
          assignees = (issue.assignee_ids + [moving_to_list.user_id]).compact

          assignees -= [moving_from_list.user_id] if both_are_list_type?('assignee') || moving_to_list.backlog?

          assignees
        end
      end
    end
  end
end
