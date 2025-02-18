# frozen_string_literal: true

module IssuablesDescriptionTemplatesHelper
  include Gitlab::Utils::StrongMemoize
  include GitlabRoutingHelper

  def template_dropdown_tag(issuable, &block)
    template_names = template_names(issuable)

    selected_template = selected_template_name(template_names)
    default_template = default_template_name(template_names, issuable)
    title = _('Choose a template')

    options = {
      toggle_class: 'js-issuable-selector',
      title: title,
      filter: true,
      placeholder: 'Filter',
      footer_content: true,
      data: {
        data: issuable_templates(ref_project, issuable.to_ability_name),
        field_name: 'issuable_template',
        selected: selected_template,
        default: default_template,
        project_id: ref_project.id
      }
    }

    dropdown_tag(title, options: options) do
      capture(&block)
    end
  end

  def issuable_templates(project, issuable_type)
    @template_types ||= {}
    @template_types[project.id] ||= {}
    @template_types[project.id][issuable_type] ||= TemplateFinder.all_template_names(project, issuable_type.pluralize)
  end

  def selected_template_name(template_names)
    template_param = params[:issuable_template]
    return if template_param.blank?

    decoded_param = CGI.unescape(template_param)
    template_names.find { |name| name == decoded_param }
  end

  def default_template_name(template_names, issuable)
    return if issuable.description.present? || issuable.persisted?

    template_names.find { |tmpl_name| tmpl_name.casecmp?('default') }
  end

  def template_names(issuable)
    # Only local templates will be listed if licenses for inherited templates are not present
    issuable_templates(ref_project, issuable.to_ability_name).values.flatten.map { |tpl| tpl[:name] }.compact.uniq
  end

  def available_service_desk_templates_for(project)
    issuable_templates(project, 'issue').flatten.to_json
  end

  def template_names_path(parent, issuable)
    return '' unless parent.is_a?(Project)

    project_template_names_path(parent, template_type: issuable.to_ability_name)
  end
end

IssuablesDescriptionTemplatesHelper.prepend_mod
