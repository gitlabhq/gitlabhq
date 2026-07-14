# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class DevelopmentCreateInputType < BaseInputObject
        graphql_name 'WorkItemWidgetDevelopmentCreateInput'

        MAX_MERGE_REQUESTS = ::MergeRequests::WorkItemRelations::BaseService::MAX_RELATIONS
        ERROR_MESSAGE = "No more than #{MAX_MERGE_REQUESTS} merge requests can be linked at the same time.".freeze

        argument :link_type, ::Types::MergeRequests::WorkItemLinkTypeEnum,
          required: false, description: 'Type of link. Defaults to `RELATED`.'
        argument :merge_request_ids, [::Types::GlobalIDType[::MergeRequest]],
          description: "Global IDs of the merge requests to link. " \
            "Maximum number of IDs you can provide: #{MAX_MERGE_REQUESTS}.",
          required: true,
          prepare: ->(ids, _ctx) do
            raise Gitlab::Graphql::Errors::ArgumentError, ERROR_MESSAGE if ids.size > MAX_MERGE_REQUESTS

            ids.map { |gid| gid.model_id.to_i }
          end
      end
    end
  end
end
