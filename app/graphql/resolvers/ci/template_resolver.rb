# frozen_string_literal: true

module Resolvers
  module Ci
    class TemplateResolver < BaseResolver
      type Types::Ci::TemplateType, null: true

      argument :name, GraphQL::STRING_TYPE, required: true,
        description: 'Name of the CI/CD template to search for.'

      alias_method :project, :object

      def resolve(name: nil)
        ::TemplateFinder.new(:gitlab_ci_ymls, project, name: name).execute
      end
    end
  end
end
