# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module CreateParams
        extend Grape::API::Helpers

        params :work_item_create_features_ee do # rubocop:disable Lint/EmptyBlock -- Overridden in EE
        end

        params :work_item_create_features do
          optional :features, type: Hash, desc: 'Input for work item features (widgets).' do
            optional :description, type: Hash, desc: 'Input for description feature.' do
              requires :description, type: String, desc: 'Description text for the work item.'
            end

            optional :assignees, type: Hash, desc: 'Input for assignees feature.' do
              requires :assignee_ids, type: Array[Integer], limit: 30,
                desc: 'IDs of users to assign to the work item. Maximum 30.'
            end

            optional :labels, type: Hash, desc: 'Input for labels feature.' do
              requires :label_ids, type: Array[Integer], limit: 30,
                desc: 'IDs of labels to add to the work item. Maximum 30.'
            end

            optional :milestone, type: Hash, desc: 'Input for milestone feature.' do
              optional :milestone_id, type: Integer, desc: 'ID of the milestone to assign. Null to unset.'
            end

            optional :hierarchy, type: Hash, desc: 'Input for hierarchy feature.' do
              optional :parent_id, type: Integer, desc: 'ID of the parent work item.'
            end

            optional :start_and_due_date, type: Hash, desc: 'Input for start and due date feature.' do
              optional :start_date, type: Date, desc: 'Start date for the work item.'
              optional :due_date, type: Date, desc: 'Due date for the work item.'
            end

            optional :linked_items, type: Hash, desc: 'Input for linked items feature.' do
              requires :work_items_ids, type: Array[Integer], limit: 30,
                desc: 'IDs of work items to link. Maximum 30.'
              optional :link_type, type: String, values: %w[relates_to], default: 'relates_to',
                desc: 'Type of link. Supported values: relates_to.'
            end

            optional :crm_contacts, type: Hash, desc: 'Input for CRM contacts widget.' do
              requires :contact_ids, type: Array[Integer],
                desc: 'IDs of CRM contacts to set on the work item.'
            end

            use :work_item_create_features_ee
          end
        end

        params :work_items_create_params do
          requires :title, type: String, desc: 'Title of the work item.'

          optional :work_item_type_name, type: String,
            values: ::WorkItems::TypesFramework::Provider.unfiltered_base_types,
            desc: 'Name of the work item type (for example, "task", "issue", "epic").'
          optional :work_item_type_id, type: Integer,
            desc: 'Numeric ID of the work item type.'
          at_least_one_of :work_item_type_name, :work_item_type_id

          optional :confidential, type: Boolean, desc: 'Whether the work item is confidential.'
          optional :created_at, type: DateTime,
            desc: 'Timestamp for the creation. Available only for admins and project owners.'

          use :work_item_create_features
        end
      end
    end
  end
end

API::Helpers::WorkItems::CreateParams.prepend_mod
