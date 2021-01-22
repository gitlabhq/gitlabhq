# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class RunnerSetupType < BaseObject
      graphql_name 'RunnerSetup'

      field :install_instructions, GraphQL::STRING_TYPE, null: false,
        description: 'Instructions for installing the runner on the specified architecture.'
      field :register_instructions, GraphQL::STRING_TYPE, null: true,
        description: 'Instructions for registering the runner.'
    end
  end
end
