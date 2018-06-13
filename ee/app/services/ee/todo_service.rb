module EE
  module TodoService
    def new_epic(epic, current_user)
      create_mention_todos(nil, epic, current_user)
    end

    def update_epic(epic, current_user, skip_users = [])
      create_mention_todos(nil, epic, current_user, nil, skip_users)
    end
  end
end
