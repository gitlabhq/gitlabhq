# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class VersionInCollectionResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::DesignManagement::VersionType, null: true

      authorize :read_design

      alias_method :collection, :object

      argument :sha, GraphQL::STRING_TYPE,
               required: false,
               description: "The SHA256 of a specific version"
      argument :id, GraphQL::ID_TYPE,
               required: false,
               description: 'The Global ID of the version'

      def resolve(id: nil, sha: nil)
        check_args(id, sha)

        gid = GitlabSchema.parse_gid(id, expected_type: ::DesignManagement::Version) if id

        ::DesignManagement::VersionsFinder
          .new(collection, current_user, sha: sha, version_id: gid&.model_id)
          .execute
          .first
      end

      def self.single
        self
      end

      private

      def check_args(id, sha)
        return if id.present? || sha.present?

        raise ::Gitlab::Graphql::Errors::ArgumentError, 'one of id or sha is required'
      end
    end
  end
end
