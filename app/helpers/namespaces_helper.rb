module NamespacesHelper
  def namespaces_options(selected = :current_user, display_path: false)
    groups = current_user.owned_groups + current_user.masters_groups
    users = [current_user.namespace]

    group_opts = ["Groups", groups.sort_by(&:human_name).map {|g| [display_path ? g.path : g.human_name, g.id]} ]
    users_opts = [ "Users", users.sort_by(&:human_name).map {|u| [display_path ? u.path : u.human_name, u.id]} ]

    options = []
    options << group_opts
    options << users_opts

    if selected == :current_user && current_user.namespace
      selected = current_user.namespace.id
    end

    grouped_options_for_select(options, selected)
  end

  def namespace_icon(namespace, size = 40)
    if namespace.kind_of?(Group)
      group_icon(namespace)
    else
      avatar_icon(namespace.owner.email, size)
    end
  end
end
