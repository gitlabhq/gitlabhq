# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class VersionInCollectionResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::DesignManagement::VersionType, null: true

      requires_argument!

      authorize :read_design

      alias_method :collection, :object

      VersionID = ::Types::GlobalIDType[::DesignManagement::Version]

      argument :id, VersionID,
        as: :version_id,
        required: false,
        description: 'Global ID of the version.'
      argument :sha, GraphQL::Types::String,
        required: false,
        description: "SHA256 of a specific version."

      def resolve(version_id: nil, sha: nil)
        check_args(version_id, sha)

        ::DesignManagement::VersionsFinder
          .new(collection, current_user, sha: sha, version_id: version_id&.model_id)
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
