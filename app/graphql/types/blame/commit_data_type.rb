# frozen_string_literal: true

module Types
  module Blame
    # rubocop: disable Graphql/AuthorizeTypes
    class CommitDataType < BaseObject
      # This is presented through `Repository` that has its own authorization
      graphql_name 'CommitData'

      field :age_map_class, GraphQL::Types::String, null: false, description: 'CSS class for age of commit.'
      field :author_avatar, GraphQL::Types::String, null: false, description: 'Link to author avatar.'
      field :commit_author_link, GraphQL::Types::String, null: false, description: 'Link to the commit author.'
      field :commit_link, GraphQL::Types::String, null: false, description: 'Link to the commit.'
      field :project_blame_link, GraphQL::Types::String,
        null: true, description: 'Link to blame prior to the change.'
      field :time_ago_tooltip, GraphQL::Types::String, null: false, description: 'Time of commit.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
