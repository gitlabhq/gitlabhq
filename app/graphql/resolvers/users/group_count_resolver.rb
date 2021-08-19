# frozen_string_literal: true

module Resolvers
  module Users
    class GroupCountResolver < BaseResolver
      type GraphQL::Types::Int, null: true

      alias_method :user, :object

      def resolve(**args)
        return unless can_read_group_count?

        BatchLoader::GraphQL.for(user.id).batch do |user_ids, loader|
          results = UserGroupsCounter.new(user_ids).execute

          results.each do |user_id, count|
            loader.call(user_id, count)
          end
        end
      end

      def can_read_group_count?
        current_user&.can?(:read_group_count, user)
      end
    end
  end
end
