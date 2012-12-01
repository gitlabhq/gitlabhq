module NamespacesHelper
  def namespaces_options(selected = :current_user, scope = :default)
    groups = current_user.namespaces.select {|n| n.type == 'Group'}

    users = if scope == :all
              Namespace.root
            else
              current_user.namespaces.reject {|n| n.type == 'Group'}
            end

    global_opts = ["Global", [['/', Namespace.global_id]] ]
    group_opts = ["Groups", groups.map {|g| [g.human_name, g.id]} ]
    users_opts = [ "Users", users.map {|u| [u.human_name, u.id]} ]

    options = []
    options << global_opts if current_user.admin
    options << group_opts
    options << users_opts

    if selected == :current_user && current_user.namespace
      selected = current_user.namespace.id
    end

    grouped_options_for_select(options, selected)
  end
end
