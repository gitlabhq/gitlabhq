# frozen_string_literal: true

module WorkItems
  class BulkMoveService
    def initialize(current_user:, work_item_ids:, source_namespace:, target_namespace:)
      @current_user = current_user
      @work_item_ids = work_item_ids
      @source_namespace = source_namespace
      @target_namespace = target_namespace
    end

    def execute
      if @target_namespace&.user_namespace?
        return response(:error, message: "User namespaces are not supported as target namespaces.")
      end

      # If the source namespace is a project and the target is a group, raise an error
      if @source_namespace&.project_namespace? && @target_namespace&.group_namespace?
        return response(:error, message: "Cannot move work items from projects to groups.")
      end

      unless @current_user.can?(:create_work_item, @target_namespace)
        return response(:error, message: "You do not have permission to move items to this namespace.")
      end

      moved_work_items =
        scoped_work_items
          .find_each(batch_size: 100) # rubocop:disable CodeReuse/ActiveRecord -- Implementation would be identical in model
          .filter_map do |work_item|
            next unless can_move_work_item?(work_item)

            begin
              move_result = ::WorkItems::DataSync::MoveService.new(
                work_item: work_item,
                current_user: @current_user,
                target_namespace: @target_namespace
              ).execute

              work_item if move_result.success? && move_result[:work_item].present?
            rescue StandardError
              nil
            end
          end

      response(:success, moved_count: moved_work_items.count)
    end

    private

    def response(status, message: nil, moved_count: 0)
      ServiceResponse.new(
        status: status,
        message: message,
        payload: { moved_work_item_count: moved_count }
      )
    end

    def can_move_work_item?(work_item)
      return false if work_item.namespace_id == @target_namespace.id
      return false unless @current_user.can?(:admin_work_item, work_item)
      return false unless work_item.supports_move_and_clone?

      true
    end

    def scoped_work_items
      WorkItem.find_on_namespaces(ids: @work_item_ids, resource_parent: @source_namespace)
    end
  end
end
