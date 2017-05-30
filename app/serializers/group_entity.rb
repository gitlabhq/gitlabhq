class GroupEntity < Grape::Entity
  include RequestAwareEntity
  include MembersHelper

  expose :id, :name, :path, :description, :visibility
  expose :avatar_url
  expose :web_url
  expose :full_name, :full_path
  expose :parent_id
  expose :created_at, :updated_at

  expose :permissions do
    expose :group_access do |group, options|
      group.group_members.find_by(user_id: request.current_user)&.access_level
    end
  end

  expose :edit_path do |group|
    edit_group_path(group)
  end

  expose :leave_path do |group|
    leave_group_group_members_path(group)
  end

  expose :can_edit do |group|
    can?(request.current_user, :admin_group, group)
  end
end
