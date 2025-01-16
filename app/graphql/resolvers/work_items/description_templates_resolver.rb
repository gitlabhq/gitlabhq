# frozen_string_literal: true

module Resolvers
  module WorkItems
    class DescriptionTemplatesResolver < BaseResolver
      type ::Types::WorkItems::DescriptionTemplateType.connection_type, null: true

      argument :name, GraphQL::Types::String,
        required: false,
        description: "Fetches the specific DescriptionTemplate."

      argument :search, GraphQL::Types::String,
        required: false,
        description: "Search for DescriptionTemplates by name.",
        deprecated: { milestone: '17.8', reason: 'search on template names is performed on the FE only' }

      alias_method :namespace, :object

      def resolve(**args)
        project = fetch_templates_project(namespace)
        return [] unless project

        template_name = args.delete(:name)

        Array.wrap(::TemplateFinder.new(:issues, project, { name: template_name }).execute)

      rescue Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError, ActiveRecord::RecordNotFound
        []
      end

      private

      def fetch_templates_project(namespace)
        return namespace.project if namespace.is_a?(::Namespaces::ProjectNamespace)

        project = Project.find(namespace.file_template_project_id)

        return unless current_user&.can?(:read_project, project)

        project
      end
    end
  end
end
