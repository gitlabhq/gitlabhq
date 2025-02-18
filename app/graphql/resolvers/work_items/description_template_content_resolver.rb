# frozen_string_literal: true

module Resolvers
  module WorkItems
    class DescriptionTemplateContentResolver < BaseResolver
      type ::Types::WorkItems::DescriptionTemplateType, null: true

      argument :template_content_input, ::Types::WorkItems::DescriptionTemplateContentInputType,
        required: true,
        description: "Input for fetching a specific Descriptiontemplate."

      def resolve(args)
        project = Project.find(args[:template_content_input].project_id)

        ::TemplateFinder.new(:issues, project, { name: args[:template_content_input].name }).execute

      rescue Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError, ActiveRecord::RecordNotFound
        nil
      end
    end
  end
end
