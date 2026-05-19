# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module UpdateParams
        extend Grape::API::Helpers

        params :work_item_update_features_ee do # rubocop:disable Lint/EmptyBlock -- Overridden in EE
        end

        params :work_item_update_features do
          optional :features, type: Hash, desc: 'Input for work item features (widgets).' do
            optional :description, type: Hash, desc: 'Input for description feature.' do
              requires :description, type: String, desc: 'Description text for the work item.'
            end

            optional :assignees, type: Hash, desc: 'Input for assignees feature.' do
              requires :assignee_ids, type: Array[Integer], limit: 30,
                desc: 'IDs of users to assign to the work item. Maximum 30.'
            end

            optional :labels, type: Hash, desc: 'Input for labels feature.' do
              optional :add_label_ids, type: Array[Integer], limit: 30,
                desc: 'IDs of labels to add to the work item. Maximum 30.'
              optional :remove_label_ids, type: Array[Integer], limit: 30,
                desc: 'IDs of labels to remove from the work item. Maximum 30.'
            end

            optional :milestone, type: Hash, desc: 'Input for milestone feature.' do
              optional :milestone_id, type: Integer, desc: 'ID of the milestone to assign. Null to unset.'
            end

            optional :hierarchy, type: Hash, desc: 'Input for hierarchy feature.' do
              optional :parent_id, type: Integer, desc: 'ID of the parent work item. Null to remove the association.'
              optional :children_ids, type: Array[Integer], limit: 30,
                desc: 'IDs of child work items to set. Maximum 30.'
            end

            optional :start_and_due_date, type: Hash, desc: 'Input for start and due date feature.' do
              optional :start_date, type: Date, desc: 'Start date for the work item.'
              optional :due_date, type: Date, desc: 'Due date for the work item.'
            end

            optional :crm_contacts, type: Hash, desc: 'Input for CRM contacts widget.' do
              requires :contact_ids, type: Array[Integer],
                desc: 'IDs of CRM contacts to set on the work item.'
              optional :operation_mode, type: String, values: %w[REPLACE APPEND REMOVE], default: 'REPLACE',
                desc: 'Operation mode for updating CRM contacts. Supported values: REPLACE, APPEND, REMOVE.'
            end

            optional :notes, type: Hash, desc: 'Input for notes widget.' do
              requires :discussion_locked, type: Boolean,
                desc: 'Whether discussion is locked on the work item.'
            end

            optional :notifications, type: Hash, desc: 'Input for notifications widget.' do
              requires :subscribed, type: Boolean,
                desc: 'Desired state of the subscription.'
            end

            optional :current_user_todos, type: Hash, desc: 'Input for current user todos widget.' do
              requires :action, type: String, values: %w[mark_as_done add],
                desc: 'Action for the to-do update. Supported values: mark_as_done, add.'
              optional :todo_id, type: Integer,
                desc: 'ID of the to-do. If not provided, all to-dos for the work item will be updated.'
            end

            optional :award_emoji, type: Hash, desc: 'Input for award emoji widget.' do
              requires :action, type: String, values: %w[add remove toggle],
                desc: 'Action for the award emoji update. Supported values: add, remove, toggle.'
              requires :name, type: String, desc: 'Name of the emoji.'
            end

            optional :time_tracking, type: Hash, desc: 'Input for time tracking widget.' do
              optional :time_estimate, type: String,
                desc: 'Time estimate in human readable format. For example: 1h 30m.'
              optional :timelog, type: Hash, desc: 'Timelog entry for time spent.' do
                requires :time_spent, type: String,
                  desc: 'Amount of time spent in human readable format. For example: 1h 30m.'
                optional :spent_at, type: DateTime,
                  desc: 'Timestamp of when the time was spent. Defaults to current timestamp.'
                optional :summary, type: String, desc: 'Summary of how the time was spent.'
              end
            end

            use :work_item_update_features_ee
          end
        end

        params :work_items_update_params do
          optional :title, type: String, desc: 'Title of the work item.'
          optional :confidential, type: Boolean, desc: 'Whether the work item is confidential.'
          optional :state_event, type: String, values: %w[close reopen],
            desc: 'Close or reopen the work item. Supported values: close, reopen.'

          use :work_item_update_features
        end
      end
    end
  end
end

API::Helpers::WorkItems::UpdateParams.prepend_mod
