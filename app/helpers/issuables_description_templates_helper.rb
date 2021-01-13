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
    strong_memoize(:issuable_templates) do
      supported_issuable_types = %w[issue merge_request]

      next [] unless supported_issuable_types.include?(issuable_type)

      template_dropdown_names(TemplateFinder.build(issuable_type.pluralize.to_sym, project).execute)
    end
  end

  private

  def issuable_templates_names(issuable)
    issuable_templates(ref_project, issuable.to_ability_name).map { |template| template[:name] }
  end

  def selected_template(issuable)
    params[:issuable_template] if issuable_templates(ref_project, issuable.to_ability_name).values.flatten.any? { |template| template[:name] == params[:issuable_template] }
  end

  def template_names_path(parent, issuable)
    return '' unless parent.is_a?(Project)

    project_template_names_path(parent, template_type: issuable.to_ability_name)
  end

  def template_dropdown_names(items)
    grouped = items.group_by(&:category)
    categories = grouped.keys

    categories.each_with_object({}) do |category, hash|
      hash[category] = grouped[category].map do |item|
        { name: item.name, id: item.key, project_id: item.try(:project_id) }
      end
    end
  end
end
