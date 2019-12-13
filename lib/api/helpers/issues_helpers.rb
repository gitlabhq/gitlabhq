# frozen_string_literal: true

module API
  module Helpers
    module IssuesHelpers
      extend Grape::API::Helpers

      params :optional_issue_params_ee do
      end

      params :optional_issues_params_ee do
      end

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
        args[:label_name] ||= args.delete(:labels)
        args[:scope] = args[:scope].underscore if args[:scope]

        IssuesFinder.new(current_user, args)
      end

      def find_issues(args = {})
        finder = issue_finder(args)
        issues = finder.execute.with_api_entity_associations

        issues.reorder(order_options_with_tie_breaker) # rubocop: disable CodeReuse/ActiveRecord
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
