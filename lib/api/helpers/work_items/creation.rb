# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module Creation
        def execute_work_item_creation(resource_parent)
          check_work_item_rest_api_feature_flag!
          authorize! :create_work_item, resource_parent

          work_item_type = resolve_work_item_type(resource_parent)
          not_found!('Work item type') unless work_item_type

          create_params = build_create_work_item_params(work_item_type)
          widget_params = extract_feature_params(resource_parent)
          validate_supported_widgets!(work_item_type, resource_parent, widget_params)

          ::WorkItems::CreateService.new(
            container: resource_parent,
            current_user: current_user,
            params: create_params,
            widget_params: widget_params
          ).execute
        end

        def render_work_item_creation(result)
          render_work_item_response(result, status: 201)
        end

        private

        def resolve_work_item_type(resource_parent)
          provider = ::WorkItems::TypesFramework::Provider.new(resource_parent)

          if params[:work_item_type_id]
            provider.find_by_id(params[:work_item_type_id])
          else
            provider.find_by_base_type(params[:work_item_type_name])
          end
        end

        def build_create_work_item_params(work_item_type)
          create_params = {
            title: params[:title],
            work_item_type: work_item_type,
            author_id: current_user.id
          }
          create_params[:confidential] = params[:confidential] unless params[:confidential].nil?
          create_params[:created_at] = params[:created_at] if params[:created_at]
          create_params
        end

        def extract_feature_params(_resource_parent)
          return {} unless params.key?(:features)

          params[:features].to_h.deep_symbolize_keys.each_with_object({}) do |(key, value), hash|
            widget_key = :"#{key}_widget"

            if key == :hierarchy && value.key?(:parent_id)
              parent_id = value.delete(:parent_id)
              parent = ::WorkItem.find_by_id(parent_id)
              not_found!("Parent work item #{parent_id}") if parent.nil?
              value[:parent] = parent
            end

            hash[widget_key] = value
          end
        end
      end
    end
  end
end

API::Helpers::WorkItems::Creation.prepend_mod
