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
          widget_params = extract_feature_params
          validate_supported_widgets!(work_item_type, resource_parent, widget_params)

          ::WorkItems::CreateService.new(
            container: resource_parent,
            current_user: current_user,
            params: create_params,
            widget_params: widget_params
          ).execute
        end

        def render_work_item_creation(result)
          if result.success?
            feature_keys = requested_feature_keys(params[:features]&.keys&.join(','))

            present result[:work_item],
              with: Entities::WorkItemBasic,
              current_user: current_user,
              requested_features: feature_keys,
              fields: requested_field_keys(params[:fields]),
              status: 201
          else
            render_api_error!(Array(result.message).join(', '), result.http_status || :unprocessable_entity)
          end
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

        def extract_feature_params
          return {} unless params.key?(:features)

          params[:features].to_h.deep_symbolize_keys.each_with_object({}) do |(key, value), hash|
            widget_key = :"#{key}_widget"

            if key == :hierarchy && value.key?(:parent_id)
              parent_id = value.delete(:parent_id)
              parent = ::WorkItem.find_by_id(parent_id)
              not_found!('Work item') if parent.nil?
              value[:parent] = parent
            end

            hash[widget_key] = value
          end
        end

        def validate_supported_widgets!(work_item_type, resource_parent, widget_params)
          unsupported = widget_params.keys - work_item_type.widget_classes(resource_parent).map(&:api_symbol)
          return if unsupported.blank?

          message = "Following widget keys are not supported by #{work_item_type.name} type: #{unsupported.join(', ')}"

          render_structured_api_error!(
            {
              error: message,
              unsupported_widgets: unsupported
            },
            :bad_request
          )
        end
      end
    end
  end
end
