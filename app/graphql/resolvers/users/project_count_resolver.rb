# frozen_string_literal: true

module Resolvers
  module Users
    class ProjectCountResolver < BaseResolver
      type GraphQL::Types::Int, null: true

      alias_method :user, :object

      def resolve(**_args)
        return unless can_read_project_count?

        BatchLoader::GraphQL.for(user.id).batch do |user_ids, loader|
          counts = ProjectAuthorization.for_user(user_ids).count_by_user_id

          user_ids.each do |id|
            loader.call(id, counts.fetch(id, 0))
          end
        end
      end

      def can_read_project_count?
        current_user&.can?(:read_user_membership_counts, user)
      end
    end
  end
end
