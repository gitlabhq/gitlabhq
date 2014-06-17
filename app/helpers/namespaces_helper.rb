module NamespacesHelper
  def namespaces_options(selected = :current_user, scope = :default)
    groups = current_user.owned_groups + current_user.masters_groups
    users = [current_user.namespace]

    group_opts = ["Groups", groups.sort_by(&:human_name).map {|g| [g.human_name, g.id]} ]
    users_opts = [ "Users", users.sort_by(&:human_name).map {|u| [u.human_name, u.id]} ]

    options = []
    options << group_opts
    options << users_opts

    if selected == :current_user && current_user.namespace
      selected = current_user.namespace.id
    end

    grouped_options_for_select(options, selected)
  end

  def namespace_select_tag(id, opts = {})
    css_class = "ajax-namespace-select "
    css_class << "multiselect " if opts[:multiple]
    css_class << (opts[:class] || '')
    value = opts[:selected] || ''

    hidden_field_tag(id, value, class: css_class)
  end
end
