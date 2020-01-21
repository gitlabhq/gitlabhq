# frozen_string_literal: true

module SelectsHelper
  def users_select_tag(id, opts = {})
    css_class = ["ajax-users-select"]
    css_class << "multiselect" if opts[:multiple]
    css_class << "skip_ldap" if opts[:skip_ldap]
    css_class << (opts[:class] || '')
    value = opts[:selected] || ''
    html = {
      class: css_class.join(' '),
      data: users_select_data_attributes(opts)
    }

    unless opts[:scope] == :all
      project = opts[:project] || @project

      if project
        html['data-project-id'] = project.id
      elsif @group
        html['data-group-id'] = @group.id
      end
    end

    hidden_field_tag(id, value, html)
  end

  def groups_select_tag(id, opts = {})
    classes = Array.wrap(opts[:class])
    classes << 'ajax-groups-select'

    # EE requires this line to be present, but there is no easy way of injecting
    # this into EE without causing merge conflicts. Given this line is very
    # simple and not really EE specific on its own, we just include it in CE.
    classes << 'multiselect' if opts[:multiple]

    opts[:class] = classes.join(' ')

    select2_tag(id, opts)
  end

  def namespace_select_tag(id, opts = {})
    opts[:class] = [*opts[:class], 'ajax-namespace-select'].join(' ')
    select2_tag(id, opts)
  end

  def project_select_tag(id, opts = {})
    opts[:class] = [*opts[:class], 'ajax-project-select'].join(' ')

    unless opts.delete(:scope) == :all
      if @group
        opts['data-group-id'] = @group.id
      end
    end

    with_feature_enabled_data_attribute =
      case opts.delete(:with_feature_enabled)
      when 'issues'         then 'data-with-issues-enabled'
      when 'merge_requests' then 'data-with-merge-requests-enabled'
      end

    opts[with_feature_enabled_data_attribute] = true

    hidden_field_tag(id, opts[:selected], opts)
  end

  def select2_tag(id, opts = {})
    klass_opts = [opts[:class]]
    klass_opts << 'multiselect' if opts[:multiple]

    opts[:class] = klass_opts.join(' ')
    value = opts[:selected] || ''

    hidden_field_tag(id, value, opts)
  end

  private

  def users_select_data_attributes(opts)
    {
      placeholder: opts[:placeholder]   || 'Search for a user',
      null_user: opts[:null_user]       || false,
      any_user: opts[:any_user]         || false,
      email_user: opts[:email_user]     || false,
      first_user: opts[:first_user] && current_user ? current_user.username : false,
      current_user: opts[:current_user] || false,
      author_id: opts[:author_id] || '',
      skip_users: opts[:skip_users] ? opts[:skip_users].map(&:id) : nil,
      qa_selector: opts[:qa_selector] || ''
    }
  end
end

SelectsHelper.prepend_if_ee('EE::SelectsHelper')
