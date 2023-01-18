# frozen_string_literal: true

module SelectsHelper
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
