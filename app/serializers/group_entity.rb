class GroupEntity < Grape::Entity
  include ActionView::Helpers::NumberHelper
  include RequestAwareEntity
  include MembersHelper
  include GroupsHelper

  expose :id, :name, :path, :description, :visibility
  expose :full_name, :full_path
  expose :web_url
  expose :parent_id
  expose :created_at, :updated_at

  expose :group_path do |group|
    group_path(group)
  end

  expose :permissions do
    expose :human_group_access do |group, options|
      group.group_members.find_by(user_id: request.current_user)&.human_access
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

  expose :has_subgroups do |group|
    GroupsFinder.new(request.current_user, parent: group).execute.any?
  end

  expose :number_projects_with_delimiter do |group|
    number_with_delimiter(GroupProjectsFinder.new(group: group, current_user: request.current_user).execute.count)
  end

  expose :number_users_with_delimiter do |group|
    number_with_delimiter(group.users.count)
  end

  expose :avatar_url do |group|
    group_icon_url(group)
  end
end
