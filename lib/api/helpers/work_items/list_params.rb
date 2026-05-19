# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module ListParams
        extend Grape::API::Helpers

        params :work_items_filter_params do
          optional :ids, type: Array[Integer],
            desc: 'Filter by work item IDs.',
            coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce
          optional :iids, type: Array[String],
            desc: 'Filter by work item IIDs.',
            coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
          optional :state, type: String,
            values: %w[opened closed all],
            desc: 'Filter by state. Values: opened, closed, or all.'
          optional :types, type: Array[String],
            values: ::WorkItems::TypesFramework::Provider.unfiltered_base_types,
            desc: 'Filter by work item types.',
            coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce

          optional :author_username, type: String,
            desc: 'Filter work items authored by one of the given usernames.'
          optional :assignee_usernames, type: Array[String],
            desc: 'Filter by assignee usernames.',
            coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
          optional :assignee_wildcard_id, type: String,
            values: %w[None Any],
            desc: 'Filter by assignee wildcard. Values: None or Any.'
          mutually_exclusive :assignee_usernames, :assignee_wildcard_id

          optional :label_name, type: Array[String],
            desc: 'Filter by label names.',
            coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
          optional :milestone_title, type: Array[String],
            desc: 'Filter by milestone titles.',
            coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
          optional :milestone_wildcard_id, type: String,
            values: %w[None Any Upcoming Started],
            desc: 'Filter by milestone wildcard. Values: None, Any, Upcoming, or Started.'
          mutually_exclusive :milestone_title, :milestone_wildcard_id

          optional :my_reaction_emoji, type: String,
            desc: 'Filter by reaction emoji applied by the current user. Wildcard values NONE and ANY are supported.'

          optional :created_before, type: DateTime,
            desc: 'Filter by created before the given date/time.'
          optional :created_after, type: DateTime,
            desc: 'Filter by created after the given date/time.'
          optional :updated_before, type: DateTime,
            desc: 'Filter by updated before the given date/time.'
          optional :updated_after, type: DateTime,
            desc: 'Filter by updated after the given date/time.'
          optional :closed_before, type: DateTime,
            desc: 'Filter by closed before the given date/time.'
          optional :closed_after, type: DateTime,
            desc: 'Filter by closed after the given date/time.'
          optional :due_before, type: DateTime,
            desc: 'Filter by due date before the given date/time.'
          optional :due_after, type: DateTime,
            desc: 'Filter by due date after the given date/time.'

          optional :search, type: String,
            desc: 'Search query for title or description.'
          optional :in, type: Array[String],
            values: ::Issuable::SEARCHABLE_FIELDS,
            desc: 'Fields to search in. Values: title, description. Requires the search argument.',
            coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce

          optional :timeframe, type: Hash,
            desc: 'List items overlapping the given timeframe.' do
            optional :start, type: Date,
              desc: 'Start of the timeframe.'
            optional :end, type: Date,
              desc: 'End of the timeframe.'
          end

          optional :confidential, type: Boolean,
            desc: 'Filter for confidential work items.'
          optional :subscribed, type: Symbol,
            values: ::API::WorkItems::SUBSCRIPTION_STATUS_ENUM.values,
            coerce_with: ->(value) { ::API::WorkItems::SUBSCRIPTION_STATUS_ENUM[value.to_s.upcase] || value },
            desc: 'Filter by subscription status. Values: EXPLICITLY_SUBSCRIBED or EXPLICITLY_UNSUBSCRIBED.'

          optional :parent_ids, type: Array[Integer],
            desc: 'Filter by parent work item IDs.',
            coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce
          optional :parent_wildcard_id, type: String,
            values: %w[None Any],
            desc: 'Filter by parent wildcard. Values: None or Any.'
          mutually_exclusive :parent_ids, :parent_wildcard_id
          optional :include_descendant_work_items, type: Boolean,
            desc: 'Include work items of descendant parents when filtering by parent_ids.'

          optional :release_tag, type: Array[String],
            desc: 'Filter by release tags. Ignored for groups.',
            coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
          optional :release_tag_wildcard_id, type: String,
            values: %w[None Any],
            desc: 'Filter by release tag wildcard. Values: None or Any.'
          mutually_exclusive :release_tag, :release_tag_wildcard_id

          optional :crm_contact_id, type: String,
            desc: 'Filter by CRM contact ID.'
          optional :crm_organization_id, type: String,
            desc: 'Filter by CRM organization ID.'

          optional :not, type: Hash,
            desc: 'Negated work item filters.' do
            optional :assignee_usernames, type: Array[String],
              desc: 'Exclude work items assigned to these usernames.',
              coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
            optional :author_username, type: Array[String],
              desc: 'Exclude work items authored by these usernames.',
              coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
            optional :label_name, type: Array[String],
              desc: 'Exclude work items with these labels.',
              coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
            optional :milestone_title, type: Array[String],
              desc: 'Exclude work items with these milestones.',
              coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
            optional :milestone_wildcard_id, type: String,
              values: %w[Started Upcoming],
              desc: 'Exclude by milestone wildcard. Values: Started or Upcoming.'
            mutually_exclusive :milestone_title, :milestone_wildcard_id
            optional :my_reaction_emoji, type: String,
              desc: 'Exclude work items with this reaction emoji.'
            optional :parent_ids, type: Array[Integer],
              desc: 'Exclude work items with these parent IDs.',
              coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce
            optional :release_tag, type: Array[String],
              desc: 'Exclude work items with these release tags.',
              coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
            optional :types, type: Array[String],
              values: ::WorkItems::TypesFramework::Provider.unfiltered_base_types,
              desc: 'Exclude work items of these types.',
              coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce

            use :work_items_not_filter_params_ee
          end

          optional :or, type: Hash,
            desc: 'List of arguments with inclusive OR.' do
            optional :assignee_usernames, type: Array[String],
              desc: 'Filter work items assigned to at least one of these usernames.',
              coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
            optional :author_usernames, type: Array[String],
              desc: 'Filter work items authored by at least one of these usernames.',
              coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
            optional :label_names, type: Array[String],
              desc: 'Filter work items with at least one of these labels.',
              coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce

            use :work_items_or_filter_params_ee
          end

          use :work_items_filter_params_ee
        end

        params :work_items_filter_params_ee do # rubocop:disable Lint/EmptyBlock -- Overridden in EE
        end

        params :work_items_not_filter_params_ee do # rubocop:disable Lint/EmptyBlock -- Overridden in EE
        end

        params :work_items_or_filter_params_ee do # rubocop:disable Lint/EmptyBlock -- Overridden in EE
        end

        params :work_items_group_filter_params do
          optional :include_ancestors, type: Boolean,
            desc: 'Include work items from ancestor groups.'
          optional :include_descendants, type: Boolean,
            desc: 'Include work items from descendant groups and projects.'
          optional :include_archived, type: Boolean, default: false,
            desc: 'Return work items from archived projects.'
        end

        params :work_items_list_params do
          use :pagination
          use :work_items_filter_params
          optional :cursor, type: String, desc: 'Cursor for obtaining the next set of records'
          optional :order_by, type: String,
            values: ::WorkItems::SortingKeys.order_by_values,
            default: 'created_at',
            desc: 'Column to sort work items by. Default: created_at.'
          optional :sort, type: String,
            values: %w[asc desc],
            default: 'desc',
            desc: 'Sort direction. Default: desc.'
          optional :fields, type: String,
            desc: ["Comma-separated list of base fields to include.",
              "Defaults to #{::API::WorkItems::DEFAULT_FIELDS.join(', ')}."].join(', ')
          optional :features, type: String,
            desc: [
              'Comma-separated list of feature payloads to include.',
              'No feature payloads are returned unless specified.',
              "Supported values: #{::API::WorkItems::FEATURE_SUPPORTED_VALUES.join(', ')}."
            ].join(' ')
        end

        params :work_items_group_list_params do
          use :work_items_list_params
          use :work_items_group_filter_params
        end
      end
    end
  end
end

API::Helpers::WorkItems::ListParams.prepend_mod_with('API::Helpers::WorkItems::ListParams')
