# frozen_string_literal: true

module API
  module Helpers
    module MergeRequestsHelpers
      extend Grape::API::Helpers
      include ::API::Helpers::CustomValidators

      params :merge_requests_base_params do
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
        optional :milestone, type: String, desc: 'Return merge requests for a specific milestone'
        optional :labels,
                 type: Array[String],
                 coerce_with: Validations::Types::LabelsList.coerce,
                 desc: 'Comma-separated list of label names'
        optional :with_labels_details, type: Boolean, desc: 'Return titles of labels and other details', default: false
        optional :created_after, type: DateTime, desc: 'Return merge requests created after the specified time'
        optional :created_before, type: DateTime, desc: 'Return merge requests created before the specified time'
        optional :updated_after, type: DateTime, desc: 'Return merge requests updated after the specified time'
        optional :updated_before, type: DateTime, desc: 'Return merge requests updated before the specified time'
        optional :view,
                 type: String,
                 values: %w[simple],
                 desc: 'If simple, returns the `iid`, URL, title, description, and basic state of merge request'
        optional :author_id, type: Integer, desc: 'Return merge requests which are authored by the user with the given ID'
        optional :assignee_id,
                 types: [Integer, String],
                 integer_none_any: true,
                 desc: 'Return merge requests which are assigned to the user with the given ID'
        optional :scope,
                 type: String,
                 values: %w[created-by-me assigned-to-me created_by_me assigned_to_me all],
                 desc: 'Return merge requests for the given scope: `created_by_me`, `assigned_to_me` or `all`'
        optional :my_reaction_emoji, type: String, desc: 'Return issues reacted by the authenticated user by the given emoji'
        optional :source_branch, type: String, desc: 'Return merge requests with the given source branch'
        optional :source_project_id, type: Integer, desc: 'Return merge requests with the given source project id'
        optional :target_branch, type: String, desc: 'Return merge requests with the given target branch'
        optional :search,
                 type: String,
                 desc: 'Search merge requests for text present in the title, description, or any combination of these'
        optional :in, type: String, desc: '`title`, `description`, or a string joining them with comma'
        optional :wip, type: String, values: %w[yes no], desc: 'Search merge requests for WIP in the title'
      end

      params :optional_scope_param do
        optional :scope,
                 type: String,
                 values: %w[created-by-me assigned-to-me created_by_me assigned_to_me all],
                 default: 'created_by_me',
                 desc: 'Return merge requests for the given scope: `created_by_me`, `assigned_to_me` or `all`'
      end
    end
  end
end
