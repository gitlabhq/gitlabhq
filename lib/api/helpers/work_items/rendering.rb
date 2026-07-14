# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module Rendering
        def render_work_items_collection_for(resource_parent)
          check_pagination_param!(params)

          authorize! :read_work_item, resource_parent
          authorize_job_token_policies!(resource_parent) if resource_parent.is_a?(::Project)

          field_keys = requested_field_keys(params[:fields])
          feature_keys = requested_feature_keys(params[:features])
          preloads = preload_associations_for(field_keys, feature_keys, resource_parent)

          work_items_relation = build_work_items_relation(
            resource_parent, preloads: (preloads + Preloads::WORK_ITEM_POLICY_PRELOADS).uniq
          )

          params[:pagination] = 'keyset' if keyset_supported_for_order?

          # `without_count` is ignored by the keyset pager and only affects the offset fallback
          # (e.g. sort=milestone), where it skips the expensive X-Total COUNT query and omits the
          # X-Total/X-Total-Pages headers entirely. This mirrors GraphQL, which also never returns
          # an exact total for this list. Next/prev page headers are still emitted for navigation.
          work_items = paginate_with_strategies(
            work_items_relation, paginator_params: { without_count: true }
          ) do |records|
            preload_hierarchy_authorization(records, feature_keys)
            records
          end.to_a

          work_items = filter_readable_work_items(work_items)

          present work_items,
            with: Entities::WorkItemBasic,
            current_user: current_user,
            scope_validator: ::Gitlab::Auth::ScopeValidator.new(
              access_token.present?, Gitlab::Auth::RequestAuthenticator.new(request)
            ),
            access_token: access_token,
            requested_features: feature_keys,
            fields: field_keys,
            resource_parent: resource_parent,
            notifications_subscriptions: preload_notifications_subscriptions(work_items, feature_keys),
            **count_preloads_for(work_items, field_keys, feature_keys)
        end

        def render_work_item_response(result, status:, notifications_subscriptions: nil)
          if result[:status] == :success
            feature_keys = requested_feature_keys(params[:features]&.keys&.join(','))
            work_item = result[:work_item]

            present work_item,
              with: Entities::WorkItemBasic,
              current_user: current_user,
              requested_features: feature_keys,
              fields: requested_field_keys(params[:fields]),
              notifications_subscriptions: notifications_subscriptions,
              # Single-item render path: opt into the participant? fallback so the entity matches GraphQL's `subscribed`
              notifications_allow_participant_fallback: true,
              status: status
          else
            render_api_error!(Array(result[:message]).join(', '), result[:http_status] || :unprocessable_entity)
          end
        end

        def render_children_for(parent_work_item)
          render_paginated_work_items_for(parent_work_item, entity: Entities::WorkItemBasic) do |preloads|
            build_children_relation(parent_work_item, state: params[:state], preloads: preloads)
          end
        end

        def render_linked_items_for(parent_work_item, link_type: nil)
          render_paginated_work_items_for(
            parent_work_item, entity: ::API::Entities::WorkItems::LinkedWorkItem
          ) do |preloads|
            build_linked_items_relation(
              parent_work_item, state: params[:state], link_type: link_type, preloads: preloads
            )
          end
        end

        # Work items are loaded via the parent relation (keyset-ordered, by relative position for children), not via
        # WorkItemsFinder. Pagination runs first so finalize sees the full page and produces a correct next-cursor,
        # then per-record :read_work_item policy filters the response in Ruby. A page may therefore present fewer items
        # than per_page when some records are not readable, but cursor advancement stays correct.
        def render_paginated_work_items_for(parent_work_item, entity:)
          check_work_item_rest_api_feature_flag!
          check_pagination_param!(params)

          authorize! :read_work_item, parent_work_item

          resource_parent = parent_work_item.resource_parent
          field_keys = requested_field_keys(params[:fields])
          feature_keys = requested_feature_keys(params[:features])
          preloads = preload_associations_for(field_keys, feature_keys, resource_parent)

          relation = yield(preloads)

          params[:pagination] = 'keyset'

          paginated = paginate_with_strategies(relation) do |records|
            preload_hierarchy_authorization(records, feature_keys)
            records
          end

          visible = filter_readable_work_items(Array(paginated))

          present visible,
            with: entity,
            current_user: current_user,
            scope_validator: ::Gitlab::Auth::ScopeValidator.new(
              access_token.present?, Gitlab::Auth::RequestAuthenticator.new(request)
            ),
            access_token: access_token,
            requested_features: feature_keys,
            fields: field_keys,
            resource_parent: resource_parent,
            notifications_subscriptions: preload_notifications_subscriptions(visible, feature_keys)
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
            fields: field_keys,
            notifications_subscriptions: preload_notifications_subscriptions([work_item], feature_keys),
            # Single-item render path: opt into the participant? fallback so the entity matches GraphQL's `subscribed`
            notifications_allow_participant_fallback: true,
            **count_preloads_for([work_item], field_keys, feature_keys)
        end

        private

        def filter_readable_work_items(work_items)
          preload_work_item_policies(work_items)

          DeclarativePolicy.user_scope do
            work_items.select { |work_item| Ability.allowed?(current_user, :read_work_item, work_item) }
          end
        end

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
