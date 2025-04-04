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

    # We call this resolver from `IssueType` where object is an `Issue` instance, and we also call this resolver
    # from `Widgets::DevelopmentType`, in which case the object is a connection type, so
    # we need to get its respective work item.
    def object
      case super
      when ::GraphQL::Pagination::Connection
        super.try(:parent)&.work_item
      else
        super
      end
    end
  end
end
