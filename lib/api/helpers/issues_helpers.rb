# frozen_string_literal: true

module API
  module Helpers
    module IssuesHelpers
      extend Grape::API::Helpers

      params :negatable_issue_filter_params_ee do
      end

      params :optional_issue_params_ee do
      end

      params :issues_stats_params_ee do
      end

      def self.create_issue_mcp_params
        [
          :id, :title, :description, :assignee_ids, :milestone_id, :labels, :confidential
        ]
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
          :title,
          :issue_type
        ]
      end

      def self.sort_options
        %w[
          created_at
          due_date
          label_priority
          milestone_due
          popularity
          priority
          relative_position
          title
          updated_at
        ]
      end

      def issue_finder(args = {})
        args = declared_params.merge(args)

        args.delete(:id)
        args[:not] ||= {}

        # Use the legacy milestone filtering in the RestAPI to avoid breaking change
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/429728
        args[:use_legacy_milestone_filtering] = true

        args[:milestone_title] ||= args.delete(:milestone)
        args[:milestone_wildcard_id] ||= args.delete(:milestone_id)
        args[:not][:milestone_title] ||= args[:not].delete(:milestone)
        args[:not][:milestone_wildcard_id] ||= args[:not].delete(:milestone_id)
        args[:label_name] ||= args.delete(:labels)
        args[:not][:label_name] ||= args[:not].delete(:labels)
        args[:scope] = args[:scope].underscore if args[:scope]
        args[:sort] = "#{args[:order_by]}_#{args[:sort]}"
        args[:issue_types] ||= args.delete(:issue_type) || WorkItems::Type.allowed_types_for_issues

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

API::Helpers::IssuesHelpers.prepend_mod_with('API::Helpers::IssuesHelpers')
