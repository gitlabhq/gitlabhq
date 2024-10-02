# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class DesignsResolver < BaseResolver
      DesignID = ::Types::GlobalIDType[::DesignManagement::Design]
      VersionID = ::Types::GlobalIDType[::DesignManagement::Version]

      type ::Types::DesignManagement::DesignType.connection_type, null: true

      argument :at_version, VersionID,
        required: false,
        description: 'Filters designs to only those that existed at the version. ' \
          'If argument is omitted or nil then all designs will reflect the latest version'
      argument :filenames, [GraphQL::Types::String],
        required: false,
        description: 'Filters designs by their filename.'
      argument :ids, [DesignID],
        required: false,
        description: 'Filters designs by their ID.'

      def self.single
        ::Resolvers::DesignManagement::DesignResolver
      end

      def resolve(ids: nil, filenames: nil, at_version: nil)
        context.scoped_set!(:at_version_argument, at_version) if at_version

        ::Gitlab::Graphql::Lazy.with_value(version(at_version)) do |visible_at|
          ::DesignManagement::DesignsFinder.new(
            issue,
            current_user,
            ids: design_ids(ids),
            filenames: filenames,
            visible_at_version: visible_at
          ).execute
        end
      end

      private

      def version(at_version)
        return unless at_version

        GitlabSchema.find_by_gid(at_version)
      end

      def design_ids(gids)
        return if gids.nil?

        gids.map(&:model_id)
      end

      def issue
        object.issue
      end
    end
  end
end
