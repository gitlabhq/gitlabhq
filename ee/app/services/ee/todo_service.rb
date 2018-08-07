module EE
  module TodoService
    extend ::Gitlab::Utils::Override

    # When new approvers are added for a merge request:
    #
    #  * create a todo for those users to approve the MR
    #
    def add_merge_request_approvers(merge_request, approvers)
      create_approval_required_todos(merge_request, approvers, merge_request.author)
    end

    override :new_issuable
    def new_issuable(issuable, author)
      if issuable.is_a?(MergeRequest)
        create_approval_required_todos(issuable, issuable.overall_approvers, author)
      end

      super
    end

    def new_epic(epic, current_user)
      create_mention_todos(nil, epic, current_user)
    end

    def update_epic(epic, current_user, skip_users = [])
      create_mention_todos(nil, epic, current_user, nil, skip_users)
    end

    private

    override :attributes_for_target
    def attributes_for_target(target)
      attributes = super

      if target.is_a?(Epic)
        attributes[:group_id] = target.group_id
      end

      attributes
    end

    def create_approval_required_todos(merge_request, approvers, author)
      attributes = attributes_for_todo(merge_request.project, merge_request, author, ::Todo::APPROVAL_REQUIRED)
      create_todos(approvers.map(&:user), attributes)
    end
  end
end
