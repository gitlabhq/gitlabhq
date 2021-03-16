# frozen_string_literal: true

module Resolvers
  class ProjectMergeRequestsResolver < MergeRequestsResolver
    type ::Types::MergeRequestType.connection_type, null: true
    accept_assignee
    accept_author
    accept_reviewer

    def resolve(**args)
      scope = super

      if only_count_is_selected_with_merged_at_filter?(args)
        MergeRequest::MetricsFinder
          .new(current_user, args.merge(target_project: project))
          .execute
      else
        scope
      end
    end

    def only_count_is_selected_with_merged_at_filter?(args)
      return unless lookahead

      argument_names = args.compact.except(:lookahead, :sort, :merged_before, :merged_after).keys

      # no extra filtering arguments are provided
      return unless argument_names.empty?
      return unless args[:merged_after] || args[:merged_before]

      # Detecting a specific query pattern:
      # mergeRequests(mergedAfter: "X", mergedBefore: "Y") {
      #   count
      #   totalTimeToMerge
      # }
      allowed_selected_fields = [:count, :total_time_to_merge]
      selected_fields = lookahead.selections.map(&:field).map(&:original_name) - [:__typename] # ignore __typename meta field

      # only the allowed_selected_fields are present
      (selected_fields - allowed_selected_fields).empty?
    end
  end
end
