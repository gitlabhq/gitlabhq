# frozen_string_literal: true

module Resolvers
  class UserDiscussionsCountResolver < BaseResolver
    # This resolver does not need to authorize object(Issue, MR, Epic, Work Item), because if object is not authorized
    # in the first place we'll not even get to query the count of discussions
    type GraphQL::Types::Int, null: true

    def resolve
      load_discussions_counts
    end

    private

    def load_discussions_counts
      BatchLoader::GraphQL.for(object.id).batch do |ids, loader, args|
        counts = Note.count_for_collection(
          ids, object.class.base_class.name, 'COUNT(DISTINCT discussion_id) as count'
        ).index_by(&:noteable_id)

        ids.each do |id|
          loader.call(id, counts[id]&.count || 0)
        end
      end
    end
  end
end

::Resolvers::UserDiscussionsCountResolver.prepend_mod
