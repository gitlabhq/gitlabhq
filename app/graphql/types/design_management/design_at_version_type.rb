# frozen_string_literal: true

module Types
  module DesignManagement
    class DesignAtVersionType < BaseObject
      graphql_name 'DesignAtVersion'

      description 'A design pinned to a specific version. ' \
        'The image field reflects the design as of the associated version'

      authorize :read_design

      delegate :design, :version, to: :object
      delegate :issue, :filename, :full_path, :diff_refs, to: :design

      implements ::Types::DesignManagement::DesignFields

      field :version,
        Types::DesignManagement::VersionType,
        null: false,
        description: 'Version this design-at-versions is pinned to.'

      field :design,
        Types::DesignManagement::DesignType,
        null: false,
        description: 'Underlying design.'

      def cached_stateful_version(_parent)
        version
      end

      def notes_count
        design.user_notes_count
      end
    end
  end
end
