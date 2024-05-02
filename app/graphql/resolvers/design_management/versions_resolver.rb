# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class VersionsResolver < BaseResolver
      type Types::DesignManagement::VersionType.connection_type, null: false

      alias_method :design_or_collection, :object

      VersionID = ::Types::GlobalIDType[::DesignManagement::Version]

      argument :earlier_or_equal_to_sha, GraphQL::Types::String,
        as: :sha,
        required: false,
        description: 'SHA256 of the most recent acceptable version.'

      argument :earlier_or_equal_to_id, VersionID,
        as: :id,
        required: false,
        description: 'Global ID of the most recent acceptable version.'

      # This resolver has a custom singular resolver
      def self.single
        ::Resolvers::DesignManagement::VersionInCollectionResolver
      end

      def resolve(id: nil, sha: nil)
        version = cutoff(id, sha)

        raise ::Gitlab::Graphql::Errors::ResourceNotAvailable, 'cutoff not found' unless version.present?

        if version == :unconstrained
          find
        else
          find(earlier_or_equal_to: version)
        end
      end

      private

      # Find the most recent version that the client will accept
      def cutoff(id, sha)
        if sha.present? || id.present?
          specific_version(id, sha)
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
    end
  end
end
