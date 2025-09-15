# frozen_string_literal: true

module Resolvers
  module WorkItems
    class DescriptionTemplateContentResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type ::Types::WorkItems::DescriptionTemplateType, null: true

      argument :template_content_input, ::Types::WorkItems::DescriptionTemplateContentInputType,
        required: true,
        description: "Input for fetching a specific description template."

      authorize :read_namespace

      def resolve(args)
        template_project = Project.find(args[:template_content_input].project_id)

        authorize_template!(template_project, args[:template_content_input].from_namespace)

        ::TemplateFinder.new(:issues, template_project,
          { name: args[:template_content_input].name, source_template_project_id: template_project.id }).execute

      rescue Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError, ActiveRecord::RecordNotFound
        nil
      end

      private

      # Overridden in EE
      def authorize_template!(template_project, _)
        authorize!(template_project.project_namespace)
      end
    end
  end
end

Resolvers::WorkItems::DescriptionTemplateContentResolver.prepend_mod
