# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class GroupVariableType < ProjectVariableType
      graphql_name 'CiGroupVariable'
      description 'CI/CD variables for a group.'

      connection_type_class Types::Ci::GroupVariableConnectionType
    end
  end
end
