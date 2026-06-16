# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module Update
        def execute_work_item_update(work_item)
          check_work_item_rest_api_feature_flag!
          authorize! :update_work_item, work_item

          update_params = build_update_work_item_params
          widget_params = extract_update_feature_params(work_item)
          validate_supported_widgets!(work_item.work_item_type, work_item.resource_parent, widget_params)

          ::WorkItems::UpdateService.new(
            container: work_item.resource_parent,
            current_user: current_user,
            params: update_params,
            widget_params: widget_params
          ).execute(work_item)
        end

        def render_work_item_update(result)
          # Update can flip subscription state via subscription_event in the same request, so the renderer needs the
          # newly loaded subscription row to report the right `subscribed` value. Create doesn't flip subscriptions, so
          # it skips this. Skipped on failure: WorkItems::UpdateService passes back the work item on validation errors,
          # but render_work_item_response calls render_api_error! on those, so the cache would be discarded.
          feature_keys = requested_feature_keys(params[:features]&.keys&.join(','))
          work_item = result[:work_item]
          subscriptions =
            if result[:status] == :success && work_item
              preload_notifications_subscriptions([work_item], feature_keys)
            else
              {}
            end

          render_work_item_response(result, status: 200, notifications_subscriptions: subscriptions)
        end

        private

        def build_update_work_item_params
          update_params = {}
          update_params[:title] = params[:title] if params.key?(:title)
          update_params[:confidential] = params[:confidential] if params.key?(:confidential)
          update_params[:state_event] = params[:state_event] if params.key?(:state_event)
          update_params
        end

        def extract_update_feature_params(work_item)
          return {} unless params.key?(:features)

          widget_params = params[:features].to_h.deep_symbolize_keys.each_with_object({}) do |(key, value), hash|
            widget_key = :"#{key}_widget"

            case key
            when :hierarchy
              if value.key?(:parent_id)
                parent_id = value.delete(:parent_id)
                if parent_id.nil?
                  value[:parent] = nil
                else
                  parent = ::WorkItem.find_by_id(parent_id)
                  not_found!("Parent work item #{parent_id}") if parent.nil?
                  value[:parent] = parent
                end
              end

              if value.key?(:children_ids)
                children_ids = value.delete(:children_ids)
                value[:children] = ::WorkItem.id_in(children_ids)
              end
            when :award_emoji
              value[:action] = value[:action].to_sym if value[:action]
            end

            hash[widget_key] = value
          end

          strip_disabled_widget_params!(widget_params, work_item.work_item_type, work_item.resource_parent)
          widget_params
        end
      end
    end
  end
end

API::Helpers::WorkItems::Update.prepend_mod
