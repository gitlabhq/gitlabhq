# frozen_string_literal: true

module Resolvers
  class MergeRequestsCountResolver < BaseResolver
    type GraphQL::Types::Int, null: true

    def resolve
      BatchLoader::GraphQL.for(object.id).batch do |ids, loader, args|
        counts = MergeRequestsClosingIssues.count_for_collection(ids, context[:current_user]).to_h

        ids.each do |id|
          loader.call(id, counts[id] || 0)
        end
      end
    end
  end
end
