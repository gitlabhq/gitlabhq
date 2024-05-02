# frozen_string_literal: true

# rubocop: disable Graphql/AuthorizeTypes
module Types
  class DesignManagementType < BaseObject
    graphql_name 'DesignManagement'

    field :version, ::Types::DesignManagement::VersionType,
      null: true,
      resolver: ::Resolvers::DesignManagement::VersionResolver,
      description: 'Find a version.'

    field :design_at_version, ::Types::DesignManagement::DesignAtVersionType,
      null: true,
      resolver: ::Resolvers::DesignManagement::DesignAtVersionResolver,
      description: 'Find a design as of a version.'
  end
end
