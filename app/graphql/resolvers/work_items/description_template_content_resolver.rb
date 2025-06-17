# frozen_string_literal: true

module Resolvers
  module WorkItems
    class DescriptionTemplateContentResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type ::Types::WorkItems::DescriptionTemplateType, null: true

      argument :template_content_input, ::Types::WorkItems::DescriptionTemplateContentInputType,
        required: true,
        description: "Input for fetching a specific description template."

      authorize :read_project

      def resolve(args)
        project = Project.find(args[:template_content_input].project_id)

        authorize!(project)

        ::TemplateFinder.new(:issues, project,
          { name: args[:template_content_input].name, source_template_project_id: project.id }).execute

      rescue Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError, ActiveRecord::RecordNotFound
        nil
      end
    end
  end
end
