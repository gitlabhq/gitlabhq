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
      field :detailed_status, Types::Ci::DetailedStatusType, null: true,
            description: 'Detailed status of the stage'

      def detailed_status
        object.detailed_status(context[:current_user])
      end
    end
  end
end
