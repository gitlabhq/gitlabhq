# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class JobType < BaseObject
      graphql_name 'CiJob'

      field :name, GraphQL::STRING_TYPE, null: true,
        description: 'Name of the job'
      field :needs, JobType.connection_type, null: true,
        description: 'Builds that must complete before the jobs run'
    end
  end
end
