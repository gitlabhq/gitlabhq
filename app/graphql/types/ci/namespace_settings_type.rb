# frozen_string_literal: true

module Types
  module Ci
    class NamespaceSettingsType < BaseObject
      graphql_name 'CiCdSettings'

      authorize :maintainer_access

      field :pipeline_variables_default_role, GraphQL::Types::String,
        null: true,
        description: 'Indicates the default minimum role required to override pipeline variables in the namespace.'
    end
  end
end
