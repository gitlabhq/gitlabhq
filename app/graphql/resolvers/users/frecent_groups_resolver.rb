# frozen_string_literal: true

module Resolvers
  module Users
    class FrecentGroupsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type [Types::GroupType], null: true

      def resolve
        return unless current_user.present?

        ::Users::GroupVisit.frecent_groups(user_id: current_user.id)
      end
    end
  end
end
