module NamespacesHelper
  def namespace_id_from(params)
    params.dig(:project, :namespace_id) || params[:namespace_id]
  end

  def namespaces_options(selected = :current_user, display_path: false, extra_group: nil)
    groups = current_user.owned_groups + current_user.masters_groups

    unless extra_group.nil? || extra_group.is_a?(Group)
      extra_group = Group.find(extra_group) if Namespace.find(extra_group).kind == 'group'
    end

    if extra_group && extra_group.is_a?(Group) && (!Group.exists?(name: extra_group.name) || Ability.allowed?(current_user, :read_group, extra_group))
      groups |= [extra_group]
    end

    users = [current_user.namespace]

    data_attr_group = { 'data-options-parent' => 'groups' }
    data_attr_users = { 'data-options-parent' => 'users' }

    group_opts = [
      "Groups", groups.sort_by(&:human_name).map { |g| [display_path ? g.full_path : g.human_name, g.id, data_attr_group] }
    ]

    users_opts = [
      "Users", users.sort_by(&:human_name).map { |u| [display_path ? u.path : u.human_name, u.id, data_attr_users] }
    ]

    options = []
    options << group_opts
    options << users_opts

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
end
