# frozen_string_literal: true

module API
  module Helpers
    module IssuesHelpers
      extend Grape::API::Helpers

      params :optional_issue_params_ee do
      end

      params :optional_issues_params_ee do
      end

      params :optional_issue_not_params_ee do
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
          :add_labels,
          :remove_labels,
          :milestone_id,
          :state_event,
          :title
        ]
      end

      def self.sort_options
        %w[created_at updated_at priority due_date relative_position label_priority milestone_due popularity]
      end

      def issue_finder(args = {})
        args = declared_params.merge(args)

        args.delete(:id)
        args[:not] ||= {}
        args[:milestone_title] ||= args.delete(:milestone)
        args[:not][:milestone_title] ||= args[:not]&.delete(:milestone)
        args[:label_name] ||= args.delete(:labels)
        args[:not][:label_name] ||= args[:not]&.delete(:labels)
        args[:scope] = args[:scope].underscore if args[:scope]
        args[:sort] = "#{args[:order_by]}_#{args[:sort]}"

        IssuesFinder.new(current_user, args)
      end

      def find_issues(args = {})
        finder = issue_finder(args)
        finder.execute.with_api_entity_associations
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

API::Helpers::IssuesHelpers.prepend_if_ee('EE::API::Helpers::IssuesHelpers')
