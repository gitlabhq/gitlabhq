# frozen_string_literal: true

module WorkItems
  class BulkUpdateService
    def initialize(parent:, current_user:, work_item_ids:, widget_params: {})
      @parent = parent
      @work_item_ids = work_item_ids
      @current_user = current_user
      @widget_params = widget_params.dup
    end

    def execute
      unless @current_user.can?(:"read_#{@parent.to_ability_name}", @parent)
        return ServiceResponse.error(message: "User can't read parent", reason: :authorization)
      end

      updated_work_items = scoped_work_items.find_each(batch_size: 100) # rubocop:disable CodeReuse/ActiveRecord -- Implementation would be identical in model
                                            .filter_map do |work_item|
        next unless @current_user.can?(:update_work_item, work_item)

        update_result = WorkItems::UpdateService.new(
          container: work_item.resource_parent,
          widget_params: @widget_params,
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
      cte.apply_to(work_item_scope).in_namespaces_with_cte(namespaces)
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
  end
end
