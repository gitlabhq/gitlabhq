# frozen_string_literal: true

module Resolvers
  module GroupMembers
    class NotificationEmailResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type GraphQL::Types::String, null: true

      def resolve
        authorize!

        BatchLoader::GraphQL.for(object.user_id).batch do |user_ids, loader|
          User.find(user_ids).each do |user|
            loader.call(user.id, user.notification_email_for(object.group))
          end
        end
      end

      def authorize!
        raise_resource_not_available_error! unless user_is_admin?
      end

      def user_is_admin?
        context[:current_user].present? && context[:current_user].can_admin_all_resources?
      end
    end
  end
end
