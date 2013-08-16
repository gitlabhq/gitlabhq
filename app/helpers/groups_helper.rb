module GroupsHelper
  def remove_user_from_group_message(group, user)
    "You are going to remove #{user.name} from #{group.name} Group. Are you sure?"
  end
end
