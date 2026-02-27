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
      params :work_items_list_params do
        use :pagination
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

      def render_work_items_collection_for(resource_parent)
        check_work_item_rest_api_feature_flag!
        check_pagination_param!(params)
        params[:pagination] = 'keyset'

        authorize! :read_work_item, resource_parent
        authorize_job_token_policies!(resource_parent) if resource_parent.is_a?(::Project)

        field_keys = (DEFAULT_FIELDS + filter_requested_keys(params[:fields], FIELD_NAME_LOOKUP)).uniq
        feature_keys = filter_requested_keys(params[:features], FEATURE_NAME_LOOKUP)

        work_items_relation = ::WorkItems::WorkItemsFinder.new(
          current_user,
          work_items_finder_params(resource_parent)
        ).execute

        preloads = preload_associations_for(field_keys, feature_keys, resource_parent)
        work_items_relation = work_items_relation.preload(*preloads) if preloads.present? # rubocop:disable CodeReuse/ActiveRecord -- Preloading associations for API response

        present paginate_with_strategies(work_items_relation),
          with: Entities::WorkItemBasic,
          current_user: current_user,
          requested_features: feature_keys,
          fields: field_keys,
          resource_parent: resource_parent
      end

      private

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
                        { project_id: resource_parent.id, exclude_group_work_items: true }
                      else
                        { group_id: resource_parent, exclude_projects: true }
                      end

        # TODO: Remove once we allow sorting param as part of the API.
        # But keep `created_at` as default when no param is present, since sorting by just `id`
        # is not performant.
        base_params.merge(sort: 'created_at_desc')
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
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden - feature flag disabled' },
            { code: 404, message: 'Not found' }
          ]
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
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden - feature flag disabled' },
            { code: 404, message: 'Not found' }
          ]
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
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden - feature flag disabled' },
            { code: 404, message: 'Not found' }
          ]
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
      end
    end
  end
end
