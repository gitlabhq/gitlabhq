# frozen_string_literal: true

module WorkItems
  class BulkUpdateService
    def initialize(parent:, current_user:, work_item_ids:, attributes: {})
      @parent = parent
      @work_item_ids = work_item_ids
      @current_user = current_user
      @attributes = attributes
    end

    def execute
      unless @current_user.can?(:"read_#{@parent.to_ability_name}", @parent)
        return ServiceResponse.error(message: "User can't read parent", reason: :authorization)
      end

      non_widget_attributes = @attributes.except(*all_widget_keys)

      updated_work_items = scoped_work_items
        .find_each(batch_size: 100) # rubocop:disable CodeReuse/ActiveRecord -- Implementation would be identical in model
        .filter_map do |work_item|
          next unless @current_user.can?(:update_work_item, work_item)

          widget_params = extract_supported_widget_params(
            work_item.work_item_type,
            @attributes,
            work_item.resource_parent
          )
          # Skip if no applicable widgets for this work item type
          next if widget_params.blank? && non_widget_attributes.blank?

          update_result = WorkItems::UpdateService.new(
            container: work_item.resource_parent,
            widget_params: widget_params,
            params: non_widget_attributes,
            current_user: @current_user
          ).execute(work_item)

          work_item if update_result[:status] == :success
        end
      ServiceResponse.success(payload: { updated_work_item_count: updated_work_items.count })
    end

    private

    def scoped_work_items
      ids = WorkItem.id_in(@work_item_ids)
      cte = Gitlab::SQL::CTE.new(:work_item_ids_cte, ids)
      work_item_scope = WorkItem.all
      cte
        .apply_to(work_item_scope)
        .in_namespaces_with_cte(namespaces)
        .includes(:work_item_type) # rubocop:disable CodeReuse/ActiveRecord -- Implementation would be identical in model
    end

    def namespaces
      relations = [group_namespaces, project_namespaces].compact

      Namespace.from_union(relations, remove_duplicates: false)
    end

    def group_namespaces
      return unless @parent.is_a?(Group)

      @parent.self_and_descendants.select(:id)
    end

    def project_namespaces
      if @parent.is_a?(Project)
        Project.id_in(@parent)
      else
        Project.in_namespace(@parent.self_and_descendant_ids)
      end.select('projects.project_namespace_id as id')
    end

    def all_widget_keys
      @all_widget_keys ||= ::WorkItems::WidgetDefinition.available_widgets.map(&:api_symbol)
    end

    def extract_supported_widget_params(work_item_type, attributes, resource_parent)
      supported_widget_keys = work_item_type.widget_classes(resource_parent).map(&:api_symbol)
      keys_to_extract = all_widget_keys & attributes.keys & supported_widget_keys

      return {} if keys_to_extract.empty?

      widget_params = attributes.slice(*keys_to_extract)

      widget_params.transform_values do |input|
        input.is_a?(Array) ? input.map(&:to_h) : input.to_h
      end
    end
  end
end
