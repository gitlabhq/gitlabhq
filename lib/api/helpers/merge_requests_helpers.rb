# frozen_string_literal: true

module API
  module Helpers
    module MergeRequestsHelpers
      extend Grape::API::Helpers
      extend ActiveSupport::Concern

      UNPROCESSABLE_ERROR_KEYS = [:project_access, :branch_conflict, :validate_fork, :base].freeze

      params :merge_requests_negatable_params do
        optional :author_id, type: Integer, desc: 'Return merge requests which are authored by the user with the given ID'
        optional :author_username, type: String, desc: 'Return merge requests which are authored by the user with the given username'
        mutually_exclusive :author_id, :author_username

        optional :assignee_id,
                 types: [Integer, String],
                 integer_none_any: true,
                 desc: 'Return merge requests which are assigned to the user with the given ID'
        optional :assignee_username, type: Array[String], check_assignees_count: true,
                 coerce_with: Validations::Validators::CheckAssigneesCount.coerce,
                 desc: 'Return merge requests which are assigned to the user with the given username'
        mutually_exclusive :assignee_id, :assignee_username

        optional :labels,
                 type: Array[String],
                 coerce_with: Validations::Types::CommaSeparatedToArray.coerce,
                 desc: 'Comma-separated list of label names'
        optional :milestone, type: String, desc: 'Return merge requests for a specific milestone'
        optional :my_reaction_emoji, type: String, desc: 'Return issues reacted by the authenticated user by the given emoji'
      end

      params :merge_requests_base_params do
        use :merge_requests_negatable_params
        optional :state,
                 type: String,
                 values: %w[opened closed locked merged all],
                 default: 'all',
                 desc: 'Return opened, closed, locked, merged, or all merge requests'
        optional :order_by,
                 type: String,
                 values: %w[created_at updated_at],
                 default: 'created_at',
                 desc: 'Return merge requests ordered by `created_at` or `updated_at` fields.'
        optional :sort,
                 type: String,
                 values: %w[asc desc],
                 default: 'desc',
                 desc: 'Return merge requests sorted in `asc` or `desc` order.'
        optional :with_labels_details, type: Boolean, desc: 'Return titles of labels and other details', default: false
        optional :with_merge_status_recheck, type: Boolean, desc: 'Request that stale merge statuses be rechecked asynchronously', default: false
        optional :created_after, type: DateTime, desc: 'Return merge requests created after the specified time'
        optional :created_before, type: DateTime, desc: 'Return merge requests created before the specified time'
        optional :updated_after, type: DateTime, desc: 'Return merge requests updated after the specified time'
        optional :updated_before, type: DateTime, desc: 'Return merge requests updated before the specified time'
        optional :view,
                 type: String,
                 values: %w[simple],
                 desc: 'If simple, returns the `iid`, URL, title, description, and basic state of merge request'

        optional :scope,
                 type: String,
                 values: %w[created-by-me assigned-to-me created_by_me assigned_to_me all],
                 desc: 'Return merge requests for the given scope: `created_by_me`, `assigned_to_me` or `all`'
        optional :source_branch, type: String, desc: 'Return merge requests with the given source branch'
        optional :source_project_id, type: Integer, desc: 'Return merge requests with the given source project id'
        optional :target_branch, type: String, desc: 'Return merge requests with the given target branch'
        optional :search,
                 type: String,
                 desc: 'Search merge requests for text present in the title, description, or any combination of these'
        optional :in, type: String, desc: '`title`, `description`, or a string joining them with comma'
        optional :wip, type: String, values: %w[yes no], desc: 'Search merge requests for WIP in the title'
        optional :not, type: Hash, desc: 'Parameters to negate' do
          use :merge_requests_negatable_params
        end

        optional :deployed_before,
          'Return merge requests deployed before the given date/time'
        optional :deployed_after,
          'Return merge requests deployed after the given date/time'
        optional :environment,
          'Returns merge requests deployed to the given environment'
      end

      params :optional_scope_param do
        optional :scope,
                 type: String,
                 values: %w[created-by-me assigned-to-me created_by_me assigned_to_me all],
                 default: 'created_by_me',
                 desc: 'Return merge requests for the given scope: `created_by_me`, `assigned_to_me` or `all`'
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
    end
  end
end
