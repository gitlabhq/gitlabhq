# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class VersionResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::DesignManagement::VersionType, null: true

      authorize :read_design

      argument :id, ::Types::GlobalIDType[::DesignManagement::Version],
        required: true,
        description: 'Global ID of the version.'

      def resolve(id:)
        authorized_find!(id: id)
      end
    end
  end
end
