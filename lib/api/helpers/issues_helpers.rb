# frozen_string_literal: true

module API
  module Helpers
    module IssuesHelpers
      def self.update_params_at_least_one_of
        [
          :assignee_id,
          :assignee_ids,
          :confidential,
          :created_at,
          :description,
          :discussion_locked,
          :due_date,
          :labels,
          :milestone_id,
          :state_event,
          :title
        ]
      end

      def issue_finder(args = {})
        args = declared_params.merge(args)

        args.delete(:id)
        args[:milestone_title] ||= args.delete(:milestone)
        args[:milestone_title] ||= args.delete(:milestone_title)
        args[:label_name] ||= args.delete(:labels)
        args[:scope] = args[:scope].underscore if args[:scope]

        IssuesFinder.new(current_user, args)
      end

      def find_issues(args = {})
        # rubocop: disable CodeReuse/ActiveRecord
        finder = issue_finder(args)
        issues = finder.execute.with_api_entity_associations
        order_by = declared_params[:sort].present? && %w(asc desc).include?(declared_params[:sort].downcase)
        issues = issues.reorder(order_options_with_tie_breaker) if order_by

        issues
        # rubocop: enable CodeReuse/ActiveRecord
      end

      def issues_statistics(args = {})
        finder = issue_finder(args)
        counter = Gitlab::IssuablesCountForState.new(finder)

        {
          statistics: {
            counts: {
              all: counter[:all],
              closed: counter[:closed],
              opened: counter[:opened]
            }
          }
        }
      end
    end
  end
end
