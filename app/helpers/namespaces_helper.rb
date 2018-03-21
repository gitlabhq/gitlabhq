module NamespacesHelper
  def namespace_id_from(params)
    params.dig(:project, :namespace_id) || params[:namespace_id]
  end

  def namespaces_options(selected = :current_user, display_path: false, extra_group: nil)
    groups = current_user.manageable_groups
               .joins(:route)
               .includes(:route)
               .order('routes.path')
    users = [current_user.namespace]

    unless extra_group.nil? || extra_group.is_a?(Group)
      extra_group = Group.find(extra_group) if Namespace.find(extra_group).kind == 'group'
    end

    if extra_group && extra_group.is_a?(Group) && (!Group.exists?(name: extra_group.name) || Ability.allowed?(current_user, :read_group, extra_group))
      groups |= [extra_group]
    end

    options = []
    options << options_for_group(groups, display_path: display_path, type: 'group')
    options << options_for_group(users, display_path: display_path, type: 'user')

    if selected == :current_user && current_user.namespace
      selected = current_user.namespace.id
    end

    grouped_options_for_select(options, selected)
  end

  def namespace_icon(namespace, size = 40)
    if namespace.is_a?(Group)
      group_icon(namespace)
    else
      avatar_icon_for_user(namespace.owner, size)
    end
  end

  private

  def options_for_group(namespaces, display_path:, type:)
    group_label = type.pluralize
    elements = namespaces.sort_by(&:human_name).map! do |n|
      [display_path ? n.full_path : n.human_name, n.id,
       data: {
         options_parent: group_label,
         visibility_level: n.visibility_level_value,
         visibility: n.visibility,
         name: n.name,
         show_path: (type == 'group') ? group_path(n) : user_path(n),
         edit_path: (type == 'group') ? edit_group_path(n) : nil
       }]
    end

    [group_label.camelize, elements]
  end
end
