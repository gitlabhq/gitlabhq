module NamespacesHelper
  def namespace_id_from(params)
    params.dig(:project, :namespace_id) || params[:namespace_id]
  end

  def namespaces_options(selected = :current_user, display_path: false, extra_group: nil)
    groups  = current_user.owned_groups + current_user.masters_groups
    users   = [current_user.namespace]
    options = []

    unless extra_group.nil? || extra_group.is_a?(Group)
      extra_group = Group.find(extra_group) if Namespace.find(extra_group).kind == 'group'
    end

    if extra_group && extra_group.is_a?(Group) && (!Group.exists?(name: extra_group.name) || Ability.allowed?(current_user, :read_group, extra_group))
      groups |= [extra_group]
    end

    options << options_for_group(groups, display_path)
    options << options_for_group(users, display_path)

    if selected == :current_user && current_user.namespace
      selected = current_user.namespace.id
    end

    grouped_options_for_select(options, selected)
  end

  def namespace_icon(namespace, size = 40)
    if namespace.is_a?(Group)
      group_icon(namespace)
    else
      avatar_icon(namespace.owner.email, size)
    end
  end

  private

  def options_for_group(namespaces, display_path)
    type = namespaces.first.is_a?(Group) ? 'group' : 'users'

    elements = namespaces.sort_by(&:human_name).map! do |n|
      [display_path ? n.full_path : n.human_name, n.id,
       data: {
         options_parent: type,
         visibility_level: n.visibility_level_value,
         visibility: n.visibility,
         name: n.name,
         show_path: n.is_a?(Group) ? group_path(n) : user_path(n),
         edit_path: n.is_a?(Group) ? edit_group_path(n) : nil
       }]
    end

    [type.camelize, elements]
  end
end
