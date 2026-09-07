# frozen_string_literal: true

module Resolvers
  class MergeRequestsCountResolver < BaseResolver
    type GraphQL::Types::Int, null: true

    def resolve
      BatchLoader::GraphQL.for(object.id).batch do |ids, loader, _args|
        counts = MergeRequestsClosingIssues.count_for_collection(ids, context[:current_user]).to_h

        ids.each do |id|
          loader.call(id, counts[id] || 0)
        end
      end
    end

    # We call this resolver from `IssueType` where object is an `Issue` instance, and we also call it from
    # `Widgets::DevelopmentType`, either on the connection's `count` field, where the object is a connection,
    # or on `closingMergeRequestsCount`, where it is the widget itself. Both need the work item behind them.
    def object
      case super
      when ::GraphQL::Pagination::Connection
        super.try(:parent)&.work_item
      when ::WorkItems::Widgets::Development
        super.work_item
      else
        super
      end
    end
  end
end
