# frozen_string_literal: true

module SelectsHelper
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
end

SelectsHelper.prepend_mod_with('SelectsHelper')
