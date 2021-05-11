# frozen_string_literal: true

class GroupChildEntity < Grape::Entity
  include ActionView::Helpers::NumberHelper
  include RequestAwareEntity
  include MarkupHelper

  expose :id, :name, :description, :visibility, :full_name,
         :created_at, :updated_at, :avatar_url

  expose :type do |instance|
    type
  end

  expose :can_edit do |instance|
    can_edit?
  end

  expose :edit_path do |instance|
    # We know `type` will be one either `project` or `group`.
    # The `edit_polymorphic_path` helper would try to call the path helper
    # with a plural: `edit_groups_path(instance)` or `edit_projects_path(instance)`
    # while our methods are `edit_group_path` or `edit_project_path`
    public_send("edit_#{type}_path", instance) # rubocop:disable GitlabSecurity/PublicSend
  end

  expose :relative_path do |instance|
    polymorphic_path(instance)
  end

  expose :permission do |instance|
    membership&.human_access
  end

  # Project only attributes
  expose :star_count, :archived,
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

  expose :markdown_description do |instance|
    markdown_description
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def membership
    return unless request.current_user

    @membership ||= request.current_user.members.find_by(source: object)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def project?
    object.is_a?(Project)
  end

  def type
    object.class.name.downcase
  end

  def markdown_description
    markdown_field(object, :description)
  end

  def can_edit?
    return false unless request.respond_to?(:current_user)

    if project?
      # Avoid checking rights for each project, as it might be expensive if the
      # user cannot read cross project.
      can?(request.current_user, :read_cross_project) &&
        can?(request.current_user, :admin_project, object)
    else
      can?(request.current_user, :admin_group, object)
    end
  end
end

GroupChildEntity.prepend_mod_with('GroupChildEntity')
