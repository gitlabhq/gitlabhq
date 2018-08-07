module EE
  module Boards
    module Issues
      module CreateService
        extend ::Gitlab::Utils::Override

        override :issue_params
        def issue_params
          assignee_ids = Array(list.user_id || board.assignee&.id)
          milestone_id = list.milestone_id || board.milestone_id

          {
            label_ids: [list.label_id, *board.label_ids],
            weight: board.weight,
            milestone_id: milestone_id,
            # This can be removed when boards have multiple assignee support.
            # See https://gitlab.com/gitlab-org/gitlab-ee/issues/3786
            assignee_ids: assignee_ids
          }
        end
      end
    end
  end
end
