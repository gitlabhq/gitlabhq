# frozen_string_literal: true

module Resolvers
  module WorkItems
    class DescriptionTemplatesResolver < BaseResolver
      type ::Types::WorkItems::DescriptionTemplateType.connection_type, null: true

      argument :name, GraphQL::Types::String,
        required: false,
        description: "Fetches the specific DescriptionTemplate.",
        deprecated: { milestone: '17.9',
                      reason: 'name and project ID are both required for fetching,
                       use DescriptionTemplateContentInputType instead' }

      argument :search, GraphQL::Types::String,
        required: false,
        description: "Search for DescriptionTemplates by name.",
        deprecated: { milestone: '17.8', reason: 'search on template names is performed on the FE only' }

      alias_method :namespace, :object

      def resolve(**_args)
        project = fetch_root_templates_project(namespace)
        return unless project

        templates = Array.wrap(::TemplateFinder.new(:issues, project).execute)

        filter_project_templates_for_group(templates) if namespace.is_a?(Group)

        return if templates.blank?

        templates

      rescue Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError, ActiveRecord::RecordNotFound
      end

      private

      # When we are at project level we return the project itself to fetch the description templates.
      # When we are at group level we fetch first found file_template_project_id from the namespace or its ancestors

      def fetch_root_templates_project(namespace)
        if namespace.is_a?(::Namespaces::ProjectNamespace)
          namespace.project
        elsif namespace.is_a?(::Group)
          Project.find(namespace.file_template_project_id)
        end
      end

      def filter_project_templates_for_group(templates)
        # Separate project templates from other templates
        project_templates, other_templates = templates.partition { |t| t.category == "Project Templates" }

        # Check if we have duplicate project and group templates from TemplateFinder where
        # project/group results match on name + content + project_id, meaning they refer to the same file
        # but the category returned refers to the parent group of the project

        has_equivalent_group_template = other_templates.any? do |other_template|
          project_templates.any? do |project_template|
            project_template.project_id == other_template.project_id &&
              project_template.name == other_template.name &&
              project_template.content == other_template.content &&
              other_template.category == "Group #{Project.find(project_template.project_id)&.parent&.name}"
          end
        end

        # If the duplicates in this case exist, we omit the project level duplicates
        templates.reject! { |t| t.category == "Project Templates" } if has_equivalent_group_template
      end
    end
  end
end

# rubocop:disable Layout/LineLength -- prepend statement is too long
Resolvers::WorkItems::DescriptionTemplatesResolver.prepend_mod_with('Resolvers::WorkItems::DescriptionTemplatesResolver')
# rubocop:enable Layout/LineLength
