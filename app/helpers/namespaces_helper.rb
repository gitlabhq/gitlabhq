# frozen_string_literal: true

module NamespacesHelper
  def namespace_id_from(params)
    params.dig(:project, :namespace_id) || params[:namespace_id]
  end

  def namespaces_options(selected = :current_user, display_path: false, groups: nil, extra_group: nil, groups_only: false)
    groups ||= current_user.manageable_groups_with_routes
    users = [current_user.namespace]
    selected_id = selected

    unless extra_group.nil? || extra_group.is_a?(Group)
      extra_group = Group.find(extra_group) if Namespace.find(extra_group).kind == 'group'
    end

    if extra_group && extra_group.is_a?(Group)
      extra_group = dedup_extra_group(extra_group)

      if Ability.allowed?(current_user, :read_group, extra_group)
        # Assign the value to an invalid primary ID so that the select box works
        extra_group.id = -1 unless extra_group.persisted?
        selected_id = extra_group.id if selected == :extra_group
        groups |= [extra_group]
      else
        selected_id = current_user.namespace.id
      end
    end

    options = []
    options << options_for_group(groups, display_path: display_path, type: 'group')

    unless groups_only
      options << options_for_group(users, display_path: display_path, type: 'user')

      if selected == :current_user && current_user.namespace
        selected_id = current_user.namespace.id
      end
    end

    grouped_options_for_select(options, selected_id)
  end

  def namespace_icon(namespace, size = 40)
    if namespace.is_a?(Group)
      group_icon_url(namespace)
    else
      avatar_icon_for_user(namespace.owner, size)
    end
  end

  def namespaces_options_with_developer_maintainer_access(options = {})
    selected = options.delete(:selected) || :current_user
    options[:groups] = current_user.manageable_groups_with_routes(include_groups_with_developer_maintainer_access: true)

    namespaces_options(selected, options)
  end

  private

  # Many importers create a temporary Group, so use the real
  # group if one exists by that name to prevent duplicates.
  # rubocop: disable CodeReuse/ActiveRecord
  def dedup_extra_group(extra_group)
    unless extra_group.persisted?
      existing_group = Group.find_by(path: extra_group.path)
      extra_group = existing_group if existing_group&.persisted?
    end

    extra_group
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def options_for_group(namespaces, display_path:, type:)
    group_label = type.pluralize
    elements = namespaces.sort_by(&:human_name).map! do |n|
      [display_path ? n.full_path : n.human_name, n.id,
       data: {
         options_parent: group_label,
         visibility_level: n.visibility_level_value,
         visibility: n.visibility,
         name: n.name,
         show_path: type == 'group' ? group_path(n) : user_path(n),
         edit_path: type == 'group' ? edit_group_path(n) : nil
       }]
    end

    [group_label.camelize, elements]
  end
end

NamespacesHelper.include_if_ee('EE::NamespacesHelper')
