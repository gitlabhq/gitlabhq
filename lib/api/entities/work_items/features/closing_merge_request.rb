# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        # Represents a merge request that closes the work item when merged, exposed by the development
        # widget's closing_merge_requests sub-endpoint. The presented object is a MergeRequest; its
        # MergeRequestsClosingIssues row (for id and from_mr_description) is looked up from
        # options[:closing_rows_by_mr_id], keyed by merge request id.
        #
        # The endpoint builds that lookup from the same ids it queries, so a row is always present.
        # The exposures still degrade to nil rather than raising if the option is missing, matching how
        # the sibling feature entities read their pre-computed options.
        class ClosingMergeRequest < Grape::Entity
          expose :id, documentation: { type: 'Integer', example: 1 } do |merge_request, options|
            options.dig(:closing_rows_by_mr_id, merge_request.id)&.id
          end

          expose :from_mr_description, documentation: { type: 'Boolean', example: true } do |merge_request, options|
            options.dig(:closing_rows_by_mr_id, merge_request.id)&.from_mr_description
          end

          expose :merge_request, using: ::API::Entities::MergeRequestBasic,
            documentation: { type: 'Entities::MergeRequestBasic' } do |merge_request, _options|
            merge_request
          end
        end
      end
    end
  end
end
