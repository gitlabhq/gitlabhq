# frozen_string_literal: true

module Types
  module ContainerRegistry
    module Protection
      class AccessLevelType < ::Types::BaseObject # rubocop:disable Graphql/AuthorizeTypes -- it inherits the same authorization as the caller
        graphql_name 'ContainerProtectionAccessLevel'
        description 'Represents the most restrictive permissions for a container image tag'

        implements Types::ContainerRegistry::Protection::AccessLevelInterface
      end
    end
  end
end
