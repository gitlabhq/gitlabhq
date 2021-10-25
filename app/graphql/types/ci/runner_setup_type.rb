# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class RunnerSetupType < BaseObject
      graphql_name 'RunnerSetup'

      field :install_instructions, GraphQL::Types::String, null: false,
        description: 'Instructions for installing the runner on the specified architecture.'
      field :register_instructions, GraphQL::Types::String, null: true,
        description: 'Instructions for registering the runner. The actual registration tokens are not included in the commands. Instead, a placeholder `$REGISTRATION_TOKEN` is shown.'
    end
  end
end
