# frozen_string_literal: true

module Types
  module Projects
    module Services
      # rubocop:disable Graphql/AuthorizeTypes
      class JiraProjectType < BaseObject
        graphql_name 'JiraProject'

        field :key, GraphQL::STRING_TYPE, null: false,
              description: 'Key of the Jira project.'
        field :project_id, GraphQL::INT_TYPE, null: false,
              description: 'ID of the Jira project.',
              method: :id
        field :name, GraphQL::STRING_TYPE, null: true,
              description: 'Name of the Jira project.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
