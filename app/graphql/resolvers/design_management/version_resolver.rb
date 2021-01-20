# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class VersionResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::DesignManagement::VersionType, null: true

      authorize :read_design

      argument :id, ::Types::GlobalIDType[::DesignManagement::Version],
               required: true,
               description: 'The Global ID of the version.'

      def resolve(id:)
        authorized_find!(id: id)
      end

      def find_object(id:)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::DesignManagement::Version].coerce_isolated_input(id)

        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
