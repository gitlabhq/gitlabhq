class GroupChildEntity < Grape::Entity
  include ActionView::Helpers::NumberHelper
  include RequestAwareEntity

  expose :id, :name, :description, :visibility, :full_name, :relative_path,
         :created_at, :updated_at, :can_edit, :type, :avatar_url, :permission, :edit_path

  def project?
    object.is_a?(Project)
  end

  def type
    object.class.name.downcase
  end

  def can_edit
    return false unless request.respond_to?(:current_user)

    if project?
      can?(request.current_user, :admin_project, object)
    else
      can?(request.current_user, :admin_group, object)
    end
  end

  def edit_path
    if project?
      edit_project_path(object)
    else
      edit_group_path(object)
    end
  end

  def relative_path
    if project?
      project_path(object)
    else
      group_path(object)
    end
  end

  def permission
    return unless request&.current_user

    request.current_user.members.find_by(source: object)&.human_access
  end

  # Project only attributes
  expose :star_count,
         if: lambda { |_instance, _options| project? }

  # Group only attributes
  expose :children_count, :leave_path, :parent_id, :number_projects_with_delimiter,
         :number_users_with_delimiter, :project_count, :subgroup_count, :can_leave,
         unless: lambda { |_instance, _options| project? }

  def leave_path
    leave_group_group_members_path(object)
  end

  def can_leave
    if membership = object.members_and_requesters.find_by(user: request.current_user)
      can?(request.current_user, :destroy_group_member, membership)
    else
      false
    end
  end

  def number_projects_with_delimiter
    number_with_delimiter(object.project_count)
  end

  def number_users_with_delimiter
    number_with_delimiter(object.member_count)
  end
end
