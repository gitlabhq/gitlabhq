# frozen_string_literal: true

module IssuablesDescriptionTemplatesHelper
  include Gitlab::Utils::StrongMemoize
  include GitlabRoutingHelper

  def template_dropdown_tag(issuable, &block)
    title = selected_template(issuable) || "Choose a template"
    options = {
      toggle_class: 'js-issuable-selector',
      title: title,
      filter: true,
      placeholder: 'Filter',
      footer_content: true,
      data: {
        data: issuable_templates(ref_project, issuable.to_ability_name),
        field_name: 'issuable_template',
        selected: selected_template(issuable),
        project_id: ref_project.id,
        project_path: ref_project.path,
        namespace_path: ref_project.namespace.full_path
      }
    }

    dropdown_tag(title, options: options) do
      capture(&block)
    end
  end

  def issuable_templates(project, issuable_type)
    @template_types ||= {}
    @template_types[project.id] ||= {}
    @template_types[project.id][issuable_type] ||= TemplateFinder.all_template_names_array(project, issuable_type.pluralize)
  end

  def issuable_templates_names(issuable)
    issuable_templates(ref_project, issuable.to_ability_name).map { |template| template[:name] }
  end

  def selected_template(issuable)
    params[:issuable_template] if issuable_templates(ref_project, issuable.to_ability_name).any? { |template| template[:name] == params[:issuable_template] }
  end

  def template_names_path(parent, issuable)
    return '' unless parent.is_a?(Project)

    project_template_names_path(parent, template_type: issuable.to_ability_name)
  end
end
