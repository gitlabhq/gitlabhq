class GroupChildEntity < Grape::Entity
  include ActionView::Helpers::NumberHelper
  include RequestAwareEntity

  expose :id, :name, :description, :visibility, :full_name,
         :created_at, :updated_at, :avatar_url

  expose :type do |instance|
    instance.class.name.downcase
  end

  expose :can_edit do |instance|
    return false unless request.respond_to?(:current_user)

    if project?
      can?(request.current_user, :admin_project, instance)
    else
      can?(request.current_user, :admin_group, instance)
    end
  end

  expose :edit_path do |instance|
    if project?
      edit_project_path(instance)
    else
      edit_group_path(instance)
    end
  end

  expose :relative_path do |instance|
    if project?
      project_path(instance)
    else
      group_path(instance)
    end
  end

  expose :permission do |instance|
    membership&.human_access
  end

  # Project only attributes
  expose :star_count,
         if: lambda { |_instance, _options| project? }

  # Group only attributes
  expose :children_count, :parent_id, :project_count, :subgroup_count,
         unless: lambda { |_instance, _options| project? }

  expose :leave_path, unless: lambda { |_instance, _options| project? } do |instance|
    leave_group_members_path(instance)
  end

  expose :can_leave, unless: lambda { |_instance, _options| project? } do |instance|
    if membership
      can?(request.current_user, :destroy_group_member, membership)
    else
      false
    end
  end

  expose :number_projects_with_delimiter, unless: lambda { |_instance, _options| project? } do |instance|
    number_with_delimiter(instance.project_count)
  end

  expose :number_users_with_delimiter, unless: lambda { |_instance, _options| project? } do |instance|
    number_with_delimiter(instance.member_count)
  end

  private

  def membership
    return unless request.current_user

    @membership ||= request.current_user.members.find_by(source: object)
  end

  def project?
    object.is_a?(Project)
  end
end
