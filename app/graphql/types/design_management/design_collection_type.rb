# frozen_string_literal: true

module Types
  module DesignManagement
    class DesignCollectionType < ::Types::BaseObject
      graphql_name 'DesignCollection'
      description 'A collection of designs'

      authorize :read_design

      field :issue, Types::IssueType, null: false,
        description: 'Issue associated with the design collection.'
      field :project, Types::ProjectType, null: false,
        description: 'Project associated with the design collection.'

      field :designs,
        Types::DesignManagement::DesignType.connection_type,
        null: false,
        resolver: Resolvers::DesignManagement::DesignsResolver,
        description: 'All designs for the design collection.',
        complexity: 5

      field :versions,
        Types::DesignManagement::VersionType.connection_type,
        resolver: Resolvers::DesignManagement::VersionsResolver,
        description: 'All versions related to all designs, ordered newest first.'

      field :version,
        Types::DesignManagement::VersionType,
        resolver: Resolvers::DesignManagement::VersionsResolver.single,
        description: 'A specific version.'

      field :design_at_version, ::Types::DesignManagement::DesignAtVersionType,
        null: true,
        resolver: ::Resolvers::DesignManagement::DesignAtVersionResolver,
        description: 'Find a design as of a version.'

      field :design, ::Types::DesignManagement::DesignType,
        null: true,
        resolver: ::Resolvers::DesignManagement::DesignResolver,
        description: 'Find a specific design.'

      field :copy_state, ::Types::DesignManagement::DesignCollectionCopyStateEnum,
        null: true,
        description: 'Copy state of the design collection.'
    end
  end
end
