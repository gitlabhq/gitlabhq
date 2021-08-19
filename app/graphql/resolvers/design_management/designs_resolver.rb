# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class DesignsResolver < BaseResolver
      DesignID = ::Types::GlobalIDType[::DesignManagement::Design]
      VersionID = ::Types::GlobalIDType[::DesignManagement::Version]

      type ::Types::DesignManagement::DesignType.connection_type, null: true

      argument :ids, [DesignID],
               required: false,
               description: 'Filters designs by their ID.'
      argument :filenames, [GraphQL::Types::String],
               required: false,
               description: 'Filters designs by their filename.'
      argument :at_version, VersionID,
               required: false,
               description: 'Filters designs to only those that existed at the version. ' \
                            'If argument is omitted or nil then all designs will reflect the latest version'

      def self.single
        ::Resolvers::DesignManagement::DesignResolver
      end

      def resolve(ids: nil, filenames: nil, at_version: nil)
        ::DesignManagement::DesignsFinder.new(
          issue,
          current_user,
          ids: design_ids(ids),
          filenames: filenames,
          visible_at_version: version(at_version)
        ).execute
      end

      private

      def version(at_version)
        return unless at_version

        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        at_version = VersionID.coerce_isolated_input(at_version)
        # TODO: when we get promises use this to make resolve lazy
        Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(at_version))
      end

      def design_ids(gids)
        return if gids.nil?

        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        gids = gids.map { |id| DesignID.coerce_isolated_input(id) }
        gids.map(&:model_id)
      end

      def issue
        object.issue
      end
    end
  end
end
