# frozen_string_literal: true

module API
  module Helpers
    module MergeRequestsHelpers
      extend Grape::API::Helpers
      extend ActiveSupport::Concern

      UNPROCESSABLE_ERROR_KEYS = [:project_access, :branch_conflict, :validate_fork, :base].freeze

      params :ee_approval_params do
        # EE-specific approval parameters
      end

      params :merge_requests_negatable_params do |options|
        optional :author_id, type: Integer,
          desc: "#{options[:prefix]}Returns merge requests created by the given user `id`. Combine with `scope=all` or `scope=assigned_to_me`."
        optional :author_username, type: String,
          desc: "#{options[:prefix]}Returns merge requests created by the given `username`."
        mutually_exclusive :author_id, :author_username
        optional :assignee_id, types: [Integer, String],
          integer_none_any: true,
          desc: "#{options[:prefix]}Returns merge requests assigned to the given user `id`. `None` returns unassigned merge requests. `Any` returns merge requests with an assignee."
        optional :assignee_username, type: Array[String],
          check_assignees_count: true,
          coerce_with: Validations::Validators::CheckAssigneesCount.coerce,
          desc: "#{options[:prefix]}Returns merge requests created by the given `username`.",
          documentation: { is_array: true }
        mutually_exclusive :assignee_id, :assignee_username
        optional :reviewer_username, type: String,
          desc: "#{options[:prefix]}Returns merge requests which have the user as a reviewer with the given `username`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Introduced in GitLab 13.8."
        optional :labels, type: Array[String],
          coerce_with: Validations::Types::CommaSeparatedToArray.coerce,
          desc: "#{options[:prefix]}Returns merge requests matching a comma-separated list of labels. `None` lists all merge requests with no labels. `Any` lists all merge requests with at least one label. Predefined names are case-insensitive.",
          documentation: { is_array: true }
        optional :milestone, type: String,
          desc: "#{options[:prefix]}Returns merge requests for a specific milestone. `None` returns merge requests with no milestone. `Any` returns merge requests that have an assigned milestone."
        optional :my_reaction_emoji, type: String,
          desc: "#{options[:prefix]}Returns merge requests reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction."
      end

      params :merge_requests_base_params do
        use :merge_requests_negatable_params, prefix: ''

        optional :reviewer_id, types: [Integer, String],
          integer_none_any: true,
          desc: 'Returns merge requests which have the user as a reviewer with the given user `id`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer.'
        mutually_exclusive :reviewer_id, :reviewer_username
        optional :state, type: String,
          values: %w[opened closed locked merged all],
          default: 'all',
          desc: 'Filter merge requests by state.'
        optional :order_by, type: String,
          values: Helpers::MergeRequestsHelpers.sort_options,
          default: 'created_at',
          desc: "Returns merge requests ordered by #{Helpers::MergeRequestsHelpers.sort_options_help} fields. Introduced in GitLab 14.8."
        optional :sort, type: String,
          values: %w[asc desc],
          default: 'desc',
          desc: 'Sort results in ascending or descending order.'
        optional :with_labels_details, type: Boolean,
          default: false,
          desc: 'If `true`, the response returns more details for each label in the labels field: `name`, `color`, `description`, `description_html`, `text_color`.'
        optional :with_merge_status_recheck, type: Boolean,
          default: false,
          desc: 'If `true`, this projection requests (but does not guarantee) an asynchronous recalculation of the `merge_status` field. Enable the `restrict_merge_status_recheck` [feature flag](https://docs.gitlab.com/administration/feature_flags/) to ignore this attribute when requested by users without the Developer, Maintainer, or Owner role.'
        optional :created_after, type: DateTime,
          desc: 'Return merge requests created on or after the specified time.',
          documentation: { example: '2019-03-15T08:00:00Z' }
        optional :created_before, type: DateTime,
          desc: 'Return merge requests created on or before the specified time.',
          documentation: { example: '2019-03-15T08:00:00Z' }
        optional :updated_after, type: DateTime,
          desc: 'Return merge requests updated on or after the specified time.',
          documentation: { example: '2019-03-15T08:00:00Z' }
        optional :updated_before, type: DateTime,
          desc: 'Return merge requests updated on or before the specified time.',
          documentation: { example: '2019-03-15T08:00:00Z' }
        optional :merged_after, type: DateTime,
          desc: 'Return merge requests merged on or after the specified time.',
          documentation: { example: '2019-03-15T08:00:00Z' }
        optional :merged_before, type: DateTime,
          desc: 'Return merge requests merged on or before the specified time.',
          documentation: { example: '2019-03-15T08:00:00Z' }
        optional :view, type: String,
          values: %w[simple],
          desc: 'If `simple`, returns the `iid`, URL, title, description, and basic state of merge request.'
        optional :scope, type: String,
          values: %w[created-by-me assigned-to-me created_by_me assigned_to_me reviews_for_me all],
          desc: 'Return merge requests for the given scope. `reviews_for_me` returns merge requests where the current user is assigned as a reviewer.'
        optional :source_branch, type: String, desc: 'Return merge requests with the given source branch.'
        optional :source_project_id, type: Integer, desc: 'Return merge requests with the given source project ID.'
        optional :target_branch, type: String, desc: 'Return merge requests with the given target branch.'
        optional :search, type: String,
          desc: 'Search merge requests against their `title` and `description`. Combine with the `in` attribute.'
        optional :in, type: String,
          desc: 'Modify the scope of the `search` attribute to `title`, `description`, or `title,description`. If omitted, defaults to `title,description`.',
          documentation: { example: 'title,description' }
        optional :wip, type: String,
          values: %w[yes no],
          desc: 'Filter merge requests by their `wip` status. `yes` returns only draft merge requests, `no` returns non-draft merge requests. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098) in GitLab 19.0. Use `draft` instead.'
        optional :draft, type: Boolean,
          desc: 'If `true`, returns only draft merge requests. If `false`, returns only non-draft merge requests.'
        mutually_exclusive :draft, :wip
        optional :not, type: Hash, desc: 'Return merge requests that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`.' do
          use :merge_requests_negatable_params, prefix: '`<Negated>` '

          optional :reviewer_id, type: Integer,
            desc: '`<Negated>` Returns merge requests which have the user as a reviewer with the given user `id`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer.'
          mutually_exclusive :reviewer_id, :reviewer_username
        end
        optional :deployed_before, type: DateTime, desc: 'Return merge requests deployed before the specified time.',
          documentation: { example: '2019-03-15T08:00:00Z' }
        optional :deployed_after, type: DateTime, desc: 'Return merge requests deployed after the specified time.',
          documentation: { example: '2019-03-15T08:00:00Z' }
        optional :environment, type: String, desc: 'Return merge requests deployed to the given environment.',
          documentation: { example: 'production' }
        optional :merge_user_id, type: Integer,
          desc: "Returns merge requests which have been merged by the user with the given user `id`."
        optional :merge_user_username, type: String,
          desc: "Returns merge requests which have been merged by the user with the given `username`."
        mutually_exclusive :merge_user_id, :merge_user_username
      end

      params :optional_scope_param do
        optional :scope, type: String,
          values: %w[created-by-me assigned-to-me created_by_me assigned_to_me reviews_for_me all],
          default: 'created_by_me',
          desc: 'Return merge requests for the given scope. `reviews_for_me` returns merge requests where the current user is assigned as a reviewer.'
      end

      def handle_merge_request_errors!(merge_request)
        return if merge_request.valid?

        errors = merge_request.errors

        UNPROCESSABLE_ERROR_KEYS.each do |error|
          unprocessable_entity!(errors[error]) if errors.has_key?(error)
        end

        conflict!(errors[:validate_branches]) if errors.has_key?(:validate_branches)

        render_validation_error!(merge_request)
      end

      def self.sort_options
        %w[
          created_at
          label_priority
          milestone_due
          popularity
          priority
          title
          updated_at
          merged_at
        ]
      end

      def self.sort_options_help
        sort_options.map { |y| "`#{y}`" }.to_sentence(last_word_connector: ' or ')
      end

      def self.create_merge_request_mcp_params
        [
          :id, :title, :source_branch, :target_branch, :target_project_id,
          :assignee_ids, :reviewer_ids, :description, :labels, :milestone_id, :milestone,
          :remove_source_branch, :squash
        ]
      end

      def self.update_merge_request_mcp_params
        [
          :id, :merge_request_iid, :title, :description, :target_branch, :state_event,
          :labels, :add_labels, :remove_labels, :assignee_ids, :reviewer_ids, :milestone_id, :milestone,
          :remove_source_branch, :squash, :discussion_locked, :allow_collaboration
        ]
      end

      # No-op method for CE - EE will override this to apply context exclusion
      def filter_diffs_for_mcp(diffs, _project)
        diffs
      end
    end
  end
end

API::Helpers::MergeRequestsHelpers.prepend_mod_with('API::Helpers::MergeRequestsHelpers')
