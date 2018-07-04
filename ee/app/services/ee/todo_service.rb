module EE
  module TodoService
    extend ::Gitlab::Utils::Override

    def new_epic(epic, current_user)
      create_mention_todos(nil, epic, current_user)
    end

    def update_epic(epic, current_user, skip_users = [])
      create_mention_todos(nil, epic, current_user, nil, skip_users)
    end

    override :attributes_for_target
    def attributes_for_target(target)
      attributes = super

      if target.is_a?(Epic)
        attributes[:group_id] = target.group_id
      end

      attributes
    end
  end
end
