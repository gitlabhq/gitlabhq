# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class StageType < BaseObject
      graphql_name 'CiStage'

      field :name, GraphQL::STRING_TYPE, null: true,
        description: 'Name of the stage'
      field :groups, Ci::GroupType.connection_type, null: true,
        description: 'Group of jobs for the stage'
    end
  end
end
