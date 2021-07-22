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

      argument :sha, GraphQL::Types::String,
               required: false,
               description: "The SHA256 of a specific version."
      argument :id, VersionID,
               as: :version_id,
               required: false,
               description: 'The Global ID of the version.'

      def resolve(version_id: nil, sha: nil)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        version_id &&= VersionID.coerce_isolated_input(version_id)

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
