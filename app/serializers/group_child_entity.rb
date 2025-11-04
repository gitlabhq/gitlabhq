# frozen_string_literal: true

class GroupChildEntity < Grape::Entity
  include ActionView::Helpers::NumberHelper
  include RequestAwareEntity
  include MarkupHelper
  include Namespaces::DeletableHelper

  expose :id, :name, :description, :visibility, :full_name, :full_path,
    :created_at, :updated_at, :avatar_url

  expose :type do |instance|
    type
  end

  expose :can_edit do |instance|
    can_edit?
  end

  expose :can_archive do |_instance|
    can_archive?
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

  expose :web_url

  expose :permission do |instance|
    membership&.human_access
  end

  expose :permission_integer do |instance|
    membership&.access_level
  end

  expose :marked_for_deletion_on

  # It is always enabled since 18.0
  expose :is_adjourned_deletion_enabled do |_instance|
    true
  end

  expose :permanent_deletion_date

  # Project only attributes
  expose :last_activity_at, if: ->(instance) { project? }

  expose :star_count, if: ->(_instance, _options) { project? }

  expose :self_or_ancestors_archived?, as: :archived

  expose :self_archived?, as: :is_self_archived

  # Group only attributes
  expose :children_count, :parent_id, unless: ->(_instance, _options) { project? }

  expose :subgroup_count, if: ->(group) { access_group_counts?(group) }

  expose :has_subgroups?, as: :has_subgroups, unless: ->(_instance) { project? }

  expose :project_count, if: ->(group) { access_group_counts?(group) }

  expose :linked_to_subscription?, as: :is_linked_to_subscription, unless: ->(_instance, _options) { project? }

  expose :leave_path, unless: ->(_instance, _options) { project? } do |instance|
    leave_group_members_path(instance)
  end

  expose :can_leave, unless: ->(_instance, _options) { project? } do |instance|
    if membership
      can?(request.current_user, :destroy_group_member, membership)
    else
      false
    end
  end

  expose :can_remove?, as: :can_remove

  expose :number_users_with_delimiter, unless: ->(_instance, _options) { project? } do |instance|
    number_with_delimiter(instance.member_count)
  end

  expose :member_count, as: :group_members_count, unless: ->(_instance, _options) { project? }

  expose :markdown_description do |instance|
    markdown_description
  end

  # For both group and project
  expose :marked_for_deletion do |instance| # rubocop:disable Style/SymbolProc -- Avoid a `ArgumentError: wrong number of arguments (given 1, expected 0)` error
    instance.scheduled_for_deletion_in_hierarchy_chain?
  end

  # For both group and project
  expose :self_deletion_in_progress?, as: :is_self_deletion_in_progress

  # For both group and project
  expose :self_deletion_scheduled?, as: :is_self_deletion_scheduled

  private

  def access_group_counts?(group)
    !project? && can?(request.current_user, :read_counts, group)
  end

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
    markdown_field_object = object.is_a?(Namespace) ? object.namespace_details : object
    markdown_field(markdown_field_object, :description)
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

  def can_archive?
    return false unless request.try(:current_user)

    ability = project? ? :archive_project : :archive_group
    can?(request.current_user, ability, object)
  end

  def can_remove?
    return false unless request.try(:current_user)

    if project?
      can?(request.current_user, :remove_project, object)
    else
      can?(request.current_user, :admin_group, object)
    end
  end

  def marked_for_deletion_on
    object.marked_for_deletion_on
  end

  def permanent_deletion_date
    permanent_deletion_date_formatted(object) || permanent_deletion_date_formatted
  end
end

GroupChildEntity.prepend_mod_with('GroupChildEntity')
