# frozen_string_literal: true

module API
  class WorkItems < ::API::Base
    include PaginationParams

    before { authenticate! }

    feature_category :portfolio_management
    urgency :low

    WORK_ITEMS_TAGS = %w[work_items].freeze
    DEFAULT_FIELDS = %i[id iid global_id title].freeze
    FULL_PATH_ID_REQUIREMENT = %r{[^/]+(?:/[^/]+)*}
    SUBSCRIPTION_STATUS_ENUM = {
      'EXPLICITLY_SUBSCRIBED' => :explicitly_subscribed,
      'EXPLICITLY_UNSUBSCRIBED' => :explicitly_unsubscribed
    }.freeze
    FIELD_NAME_LOOKUP = ::API::Entities::WorkItemBasic.root_exposures.each_with_object({}) do |exposure, hash|
      key = exposure.key
      hash[key.to_s] = key
    end.freeze
    ALL_FIELDS = FIELD_NAME_LOOKUP.values.uniq.freeze
    FEATURE_NAME_LOOKUP = ::API::Entities::WorkItems::Features::Entity
      .root_exposures
      .each_with_object({}) do |exposure, hash|
        key = exposure.key.to_sym
        hash[key.to_s] = key
      end.freeze
    FEATURE_SUPPORTED_VALUES = FEATURE_NAME_LOOKUP.keys.freeze
    FAILURE_RESPONSES = [
      { code: 400, message: 'Bad request' },
      { code: 401, message: 'Unauthorized' },
      { code: 403, message: 'Forbidden - feature flag disabled' },
      { code: 404, message: 'Not found' }
    ].freeze

    FEATURE_PRELOADS = {
      description: [:last_edited_by],
      assignees: [:assignees],
      labels: [:labels],
      milestone: [:milestone],
      start_and_due_date: [:dates_source]
    }.freeze

    PROJECT_FEATURE_PRELOADS = {
      milestone: [{ milestone: :project }]
    }.freeze

    GROUP_FEATURE_PRELOADS = {
      milestone: [{ milestone: :group }]
    }.freeze

    FIELD_PRELOADS = {
      author: [:author],
      work_item_type: [:work_item_type],
      duplicated_to_work_item_url: [:duplicated_to],
      moved_to_work_item_url: [:moved_to],
      promoted_to_epic_url: [:work_item_transition],
      web_url: [:author, :work_item_type],
      web_path: [:author, :work_item_type]
    }.freeze

    PROJECT_FIELD_PRELOADS = {
      create_note_email: [:project],
      reference: [{ namespace: :route }, { project: :namespace }],
      web_url: [{ namespace: :route }, { project: :namespace }],
      web_path: [{ namespace: :route }, { project: :namespace }],
      user_permissions: [:project],
      features: [:work_item_type, :project]
    }.freeze

    GROUP_FIELD_PRELOADS = {
      reference: [{ namespace: :route }],
      web_url: [{ namespace: :route }],
      web_path: [{ namespace: :route }],
      user_permissions: [:namespace],
      features: [:work_item_type, { namespace: :route }]
    }.freeze

    helpers do
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
          values: ::WorkItems::Type.base_types.keys,
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

        optional :confidential, type: Boolean,
          desc: 'Filter for confidential work items.'
        optional :subscribed, type: Symbol,
          values: SUBSCRIPTION_STATUS_ENUM.values,
          coerce_with: ->(value) { SUBSCRIPTION_STATUS_ENUM[value.to_s.upcase] || value },
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
            values: ::WorkItems::Type.base_types.keys,
            desc: 'Exclude work items of these types.',
            coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce
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
        end
      end

      params :work_items_list_params do
        use :pagination
        use :work_items_filter_params
        optional :cursor, type: String, desc: 'Cursor for obtaining the next set of records'
        optional :fields, type: String,
          desc: "Comma-separated list of base fields to include. Defaults to #{DEFAULT_FIELDS.join(', ')}."
        optional :features, type: String,
          desc: [
            'Comma-separated list of feature payloads to include.',
            'No feature payloads are returned unless specified.',
            "Supported values: #{FEATURE_SUPPORTED_VALUES.join(', ')}."
          ].join(' ')
      end

      params :work_item_show_params do
        optional :fields, type: String,
          desc: "Comma-separated list of base fields to include. Defaults to #{DEFAULT_FIELDS.join(', ')}."
        optional :features, type: String,
          desc: [
            'Comma-separated list of feature payloads to include.',
            'No feature payloads are returned unless specified.',
            "Supported values: #{FEATURE_SUPPORTED_VALUES.join(', ')}."
          ].join(' ')
      end

      def render_work_items_collection_for(resource_parent)
        check_work_item_rest_api_feature_flag!
        check_pagination_param!(params)
        params[:pagination] = 'keyset'

        authorize! :read_work_item, resource_parent
        authorize_job_token_policies!(resource_parent) if resource_parent.is_a?(::Project)

        field_keys = requested_field_keys(params[:fields])
        feature_keys = requested_feature_keys(params[:features])
        preloads = preload_associations_for(field_keys, feature_keys, resource_parent)

        work_items_relation = build_work_items_relation(resource_parent, preloads: preloads)

        present paginate_with_strategies(work_items_relation),
          with: Entities::WorkItemBasic,
          current_user: current_user,
          requested_features: feature_keys,
          fields: field_keys,
          resource_parent: resource_parent
      end

      def render_work_item_for(resource_parent, work_item_iid)
        check_work_item_rest_api_feature_flag!

        authorize! :read_work_item, resource_parent
        authorize_job_token_policies!(resource_parent) if resource_parent.is_a?(::Project)

        field_keys = requested_field_keys(params[:fields])
        feature_keys = requested_feature_keys(params[:features])
        preloads = preload_associations_for(field_keys, feature_keys, resource_parent)

        work_item = build_work_items_relation(resource_parent, preloads: preloads)
          .without_order
          .find_by_iid(work_item_iid)

        not_found!('Work Item') unless work_item

        present work_item,
          with: Entities::WorkItemBasic,
          current_user: current_user,
          requested_features: feature_keys,
          fields: field_keys
      end

      private

      def build_work_items_relation(resource_parent, preloads: [])
        work_items_relation = ::WorkItems::WorkItemsFinder.new(
          current_user,
          work_items_finder_params(resource_parent)
        ).execute

        return work_items_relation if preloads.blank?

        work_items_relation.preload(*preloads) # rubocop:disable CodeReuse/ActiveRecord -- Preloading associations for API response
      end

      def requested_field_keys(requested_fields)
        (DEFAULT_FIELDS + filter_requested_keys(requested_fields, FIELD_NAME_LOOKUP)).uniq
      end

      def requested_feature_keys(requested_features)
        filter_requested_keys(requested_features, FEATURE_NAME_LOOKUP)
      end

      def check_pagination_param!(params)
        return unless params[:pagination].present? && params[:pagination].to_s != 'keyset'

        render_structured_api_error!({ error: 'Only keyset pagination is supported for work items endpoints.' }, 405)
      end

      def check_work_item_rest_api_feature_flag!
        return if Feature.enabled?(:work_item_rest_api, current_user)

        forbidden!('work_item_rest_api feature flag is disabled for this user')
      end

      def work_items_finder_params(resource_parent)
        base_params = if resource_parent.is_a?(::Project)
                        { project_id: resource_parent.id }
                      else
                        { group_id: resource_parent }
                      end

        transformer = ::API::Helpers::WorkItemsFilterParams.new(params)
        filter_params = transformer.transform

        # TODO: Remove once we allow sorting param as part of the API.
        # But keep `created_at` as default when no param is present, since sorting by just `id`
        # is not performant.
        base_params.merge(filter_params).merge(sort: 'created_at_desc')
      end

      def filter_requested_keys(requested_param, available_keys)
        return [] if requested_param.nil?

        requested_param
          .split(',')
          .map { |value| value.strip.downcase }
          .reject(&:blank?)
          .filter_map { |value| available_keys[value] }
          .uniq
      end

      def preload_associations_for(field_keys, feature_keys, resource_parent)
        is_project = resource_parent.is_a?(::Project)

        context_field_preloads, context_feature_preloads =
          if is_project
            [PROJECT_FIELD_PRELOADS, PROJECT_FEATURE_PRELOADS]
          else
            [GROUP_FIELD_PRELOADS, GROUP_FEATURE_PRELOADS]
          end

        field_preloads = field_keys.flat_map do |field|
          FIELD_PRELOADS.fetch(field, []) + context_field_preloads.fetch(field, [])
        end

        feature_preloads = feature_keys.flat_map do |feature|
          FEATURE_PRELOADS.fetch(feature, []) + context_feature_preloads.fetch(feature, [])
        end

        (field_preloads + feature_preloads).uniq
      end
    end

    resource :namespaces do
      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded full path of the namespace'
      end

      namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
        desc 'List work items.' do
          detail <<~DETAIL
            Get a list of work items in a namespace. Project and group namespaces are supported.
            This feature is currently experimental and is behind the `work_item_rest_api` feature flag.
          DETAIL
          hidden true
          success Entities::WorkItemBasic
          failure FAILURE_RESPONSES
          is_array true
          tags WORK_ITEMS_TAGS
        end
        params do
          use :work_items_list_params
        end
        route_setting :authorization,
          permissions: :read_work_item,
          boundaries: [{ boundary_type: :group }, { boundary_type: :project }],
          job_token_policies: :read_work_items
        get do
          namespace = find_namespace_by_path!(params[:id].to_s, allow_project_namespaces: true)
          not_found!('Namespace') if namespace.is_a?(::Namespaces::UserNamespace)
          resource_parent = namespace.is_a?(::Namespaces::ProjectNamespace) ? namespace.project : namespace

          render_work_items_collection_for(resource_parent)
        end

        desc 'Get a work item.' do
          detail <<~DETAIL
            Get a single work item in a namespace. Project and group namespaces are supported.
            This feature is currently experimental and is behind the `work_item_rest_api` feature flag.
          DETAIL
          hidden true
          success Entities::WorkItemBasic
          failure FAILURE_RESPONSES
          tags WORK_ITEMS_TAGS
        end
        params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
          use :work_item_show_params
        end
        route_setting :authorization,
          permissions: :read_work_item,
          boundaries: [{ boundary_type: :group }, { boundary_type: :project }],
          job_token_policies: :read_work_items
        get ':work_item_iid' do
          namespace = find_namespace_by_path!(params[:id].to_s, allow_project_namespaces: true)
          not_found!('Namespace') if namespace.is_a?(::Namespaces::UserNamespace)
          resource_parent = namespace.is_a?(::Namespaces::ProjectNamespace) ? namespace.project : namespace

          render_work_item_for(resource_parent, params[:work_item_iid])
        end
      end
    end

    resource :projects do
      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end

      namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
        desc 'List work items in a project.' do
          detail <<~DETAIL
            Get a list of work items in a project.
            This feature is currently experimental and is behind the `work_item_rest_api` feature flag.
          DETAIL
          hidden true
          success Entities::WorkItemBasic
          failure FAILURE_RESPONSES
          is_array true
          tags WORK_ITEMS_TAGS
        end
        params do
          use :work_items_list_params
        end
        route_setting :authorization,
          permissions: :read_work_item,
          boundary_type: :project,
          job_token_policies: :read_work_items
        get do
          project = find_project!(params[:id])

          render_work_items_collection_for(project)
        end

        desc 'Get a work item in a project.' do
          detail <<~DETAIL
            Get a single work item in a project.
            This feature is currently experimental and is behind the `work_item_rest_api` feature flag.
          DETAIL
          hidden true
          success Entities::WorkItemBasic
          failure FAILURE_RESPONSES
          tags WORK_ITEMS_TAGS
        end
        params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
          use :work_item_show_params
        end
        route_setting :authorization,
          permissions: :read_work_item,
          boundary_type: :project,
          job_token_policies: :read_work_items
        get ':work_item_iid' do
          project = find_project!(params[:id])

          render_work_item_for(project, params[:work_item_iid])
        end
      end
    end

    resource :groups do
      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
      end

      namespace ':id/-/work_items', requirements: { id: FULL_PATH_ID_REQUIREMENT } do
        desc 'List work items in a group.' do
          detail <<~DETAIL
            Get a list of work items in a group.
            This feature is currently experimental and is behind the `work_item_rest_api` feature flag.
          DETAIL
          hidden true
          success Entities::WorkItemBasic
          failure FAILURE_RESPONSES
          is_array true
          tags WORK_ITEMS_TAGS
        end
        params do
          use :work_items_list_params
        end
        route_setting :authorization,
          permissions: :read_work_item,
          boundary_type: :group
        get do
          group = find_group!(params[:id])

          render_work_items_collection_for(group)
        end

        desc 'Get a work item in a group.' do
          detail <<~DETAIL
            Get a single work item in a group.
            This feature is currently experimental and is behind the `work_item_rest_api` feature flag.
          DETAIL
          hidden true
          success Entities::WorkItemBasic
          failure FAILURE_RESPONSES
          tags WORK_ITEMS_TAGS
        end
        params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
          use :work_item_show_params
        end
        route_setting :authorization,
          permissions: :read_work_item,
          boundary_type: :group
        get ':work_item_iid' do
          group = find_group!(params[:id])

          render_work_item_for(group, params[:work_item_iid])
        end
      end
    end
  end
end
