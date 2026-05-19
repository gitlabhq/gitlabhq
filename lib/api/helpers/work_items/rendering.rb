# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module Rendering
        def render_work_items_collection_for(resource_parent)
          check_work_item_rest_api_feature_flag!
          check_pagination_param!(params)

          authorize! :read_work_item, resource_parent
          authorize_job_token_policies!(resource_parent) if resource_parent.is_a?(::Project)

          field_keys = requested_field_keys(params[:fields])
          feature_keys = requested_feature_keys(params[:features])
          preloads = preload_associations_for(field_keys, feature_keys, resource_parent)

          work_items_relation = build_work_items_relation(resource_parent, preloads: preloads)

          params[:pagination] = 'keyset' if keyset_supported_for_order?

          paginated = paginate_with_strategies(work_items_relation) do |records|
            preload_hierarchy_authorization(records, feature_keys)
            records
          end

          present paginated,
            with: Entities::WorkItemBasic,
            current_user: current_user,
            scope_validator: ::Gitlab::Auth::ScopeValidator.new(
              access_token.present?, Gitlab::Auth::RequestAuthenticator.new(request)
            ),
            access_token: access_token,
            requested_features: feature_keys,
            fields: field_keys,
            resource_parent: resource_parent
        end

        def render_work_item_response(result, status:)
          if result[:status] == :success
            feature_keys = requested_feature_keys(params[:features]&.keys&.join(','))

            present result[:work_item],
              with: Entities::WorkItemBasic,
              current_user: current_user,
              requested_features: feature_keys,
              fields: requested_field_keys(params[:fields]),
              status: status
          else
            render_api_error!(Array(result[:message]).join(', '), result[:http_status] || :unprocessable_entity)
          end
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

          preload_hierarchy_authorization([work_item], feature_keys)

          present work_item,
            with: Entities::WorkItemDetail,
            current_user: current_user,
            scope_validator: ::Gitlab::Auth::ScopeValidator.new(
              access_token.present?, Gitlab::Auth::RequestAuthenticator.new(request)
            ),
            access_token: access_token,
            requested_features: feature_keys,
            fields: field_keys
        end

        private

        def keyset_supported_for_order?
          ::WorkItem.supported_keyset_orderings[params[:order_by].to_sym]&.include?(params[:sort].to_sym)
        end

        def requested_field_keys(requested_fields)
          (::API::WorkItems::DEFAULT_FIELDS + filter_requested_keys(
            requested_fields, ::API::WorkItems::FIELD_NAME_LOOKUP
          )).uniq
        end

        def requested_feature_keys(requested_features)
          filter_requested_keys(requested_features, ::API::WorkItems::FEATURE_NAME_LOOKUP)
        end

        def check_pagination_param!(params)
          return unless params[:pagination].present? && params[:pagination].to_s != 'keyset'

          render_structured_api_error!(
            { error: 'Explicitly setting offset pagination is not supported. ' \
                'Pagination is determined automatically based on the sort parameter.' },
            405
          )
        end

        def check_work_item_rest_api_feature_flag!
          return if Feature.enabled?(:work_item_rest_api, current_user)

          forbidden!('work_item_rest_api feature flag is disabled for this user')
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
      end
    end
  end
end
