# frozen_string_literal: true

module WorkItems
  module DataSync
    class BaseService < ::BaseContainerService
      attr_reader :work_item, :new_work_item, :target_namespace

      # work_item - original work item
      # target_namespace - ProjectNamespace(not Project) or Group
      # current_user - user performing the move/clone action
      def initialize(work_item:, target_namespace:, current_user: nil, params: {})
        @work_item = work_item
        @target_namespace = target_namespace

        super(container: work_item.namespace, current_user: current_user, params: params)
      end

      def execute
        verify_work_item_action_permission!

        ::ApplicationRecord.transaction do
          @new_work_item = data_sync_action
        end

        new_work_item
      end

      private

      def verify_work_item_action_permission!; end

      def data_sync_action; end
    end
  end
end
