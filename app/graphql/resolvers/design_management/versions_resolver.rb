# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class VersionsResolver < BaseResolver
      type Types::DesignManagement::VersionType.connection_type, null: false

      alias_method :design_or_collection, :object

      VersionID = ::Types::GlobalIDType[::DesignManagement::Version]

      extras [:parent]

      argument :earlier_or_equal_to_sha, GraphQL::STRING_TYPE,
               as: :sha,
               required: false,
               description: 'The SHA256 of the most recent acceptable version.'

      argument :earlier_or_equal_to_id, VersionID,
               as: :id,
               required: false,
               description: 'The Global ID of the most recent acceptable version.'

      # This resolver has a custom singular resolver
      def self.single
        ::Resolvers::DesignManagement::VersionInCollectionResolver
      end

      def resolve(parent: nil, id: nil, sha: nil)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id &&= VersionID.coerce_isolated_input(id)
        version = cutoff(parent, id, sha)

        raise ::Gitlab::Graphql::Errors::ResourceNotAvailable, 'cutoff not found' unless version.present?

        if version == :unconstrained
          find
        else
          find(earlier_or_equal_to: version)
        end
      end

      private

      # Find the most recent version that the client will accept
      def cutoff(parent, id, sha)
        if sha.present? || id.present?
          specific_version(id, sha)
        elsif at_version = at_version_arg(parent)
          by_id(at_version)
        else
          :unconstrained
        end
      end

      def specific_version(gid, sha)
        find(sha: sha, version_id: gid&.model_id).first
      end

      def find(**params)
        ::DesignManagement::VersionsFinder
          .new(design_or_collection, current_user, params)
          .execute
          .with_author
      end

      def by_id(gid)
        ::Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(gid))
      end

      # Find an `at_version` argument passed to a parent node.
      #
      # If one is found, then a design collection further up the AST
      # has been filtered to reflect designs at that version, and so
      # for consistency we should only present versions up to the given
      # version here.
      def at_version_arg(parent)
        # TODO: remove coercion when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        version_id = ::Gitlab::Graphql::FindArgumentInParent.find(parent, :at_version, limit_depth: 4)
        version_id &&= VersionID.coerce_isolated_input(version_id)
        version_id
      end
    end
  end
end
