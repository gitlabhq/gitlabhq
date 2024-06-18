# frozen_string_literal: true

module Resolvers
  module DesignManagement
    class DesignAtVersionResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::DesignManagement::DesignAtVersionType, null: false

      authorize :read_design

      argument :id, ::Types::GlobalIDType[::DesignManagement::DesignAtVersion],
        required: true,
        description: 'Global ID of the design at the version.'

      def resolve(id:)
        authorized_find!(id: id)
      end

      def find_object(id:)
        dav = GitlabSchema.find_by_gid(id)
        return unless consistent?(dav)

        dav
      end

      def self.single
        self
      end

      private

      # If this resolver is mounted on something that has an issue
      # (such as design collection for instance), then we should check
      # that the DesignAtVersion as found by its ID does in fact belong
      # to this issue.
      def consistent?(dav)
        issue.nil? || (dav.present? && dav.design&.issue_id == issue.id)
      end

      def issue
        object&.issue
      end
    end
  end
end
