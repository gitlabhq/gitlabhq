module NamespacesHelper
  def namespaces_options(selected = :current_user, extra_groups = [], display_path: false)
    groups = current_user.owned_groups + current_user.masters_groups

    groups += process_extra_groups(extra_groups) if extra_groups.any?

    users = [current_user.namespace]

    data_attr_group = { 'data-options-parent' => 'groups' }
    data_attr_users = { 'data-options-parent' => 'users' }

    group_opts = [
      "Groups", groups.sort_by(&:human_name).map { |g| [display_path ? g.path : g.human_name, g.id, data_attr_group] }
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

  def process_extra_groups(extra_groups)
    # Remove duplicate groups - we either keep the ones that exist for the user
    # (already in groups) or ignore those that do not belong to the user.
    duplicated_groups = extra_groups.map { |name| Namespace.where(name: name).map(&:name) }
    extra_groups = extra_groups - duplicated_groups.flatten

    extra_groups.map { |name| Group.new(name: name) }
  end

  def namespace_icon(namespace, size = 40)
    if namespace.kind_of?(Group)
      group_icon(namespace)
    else
      avatar_icon(namespace.owner.email, size)
    end
  end
end
