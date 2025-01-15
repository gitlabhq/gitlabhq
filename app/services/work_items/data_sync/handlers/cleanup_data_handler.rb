# frozen_string_literal: true

module WorkItems
  module DataSync
    module Handlers
      class CleanupDataHandler
        attr_reader :work_item, :current_user, :params

        def initialize(work_item:, current_user: nil, params: {})
          @work_item = work_item
          @current_user = current_user
          @params = params
        end

        def execute
          if cleanup_data_source_work_item_data?
            cleanup_work_item_widgets_data
            cleanup_work_item_non_widgets_data
          end

          cleanup_work_item
        end

        private

        def cleanup_data_source_work_item_data?
          Feature.enabled?(:cleanup_data_source_work_item_data, work_item.resource_parent)
        end

        def cleanup_work_item_widgets_data
          work_item.widgets.each do |widget|
            sync_data_callback_class = widget.class.sync_data_callback_class
            next if sync_data_callback_class.nil?

            data_handler = sync_data_callback_class.new(
              work_item: work_item,
              target_work_item: nil,
              current_user: current_user,
              params: params
            )
            data_handler.post_move_cleanup
          end
        end

        def cleanup_work_item_non_widgets_data
          WorkItem.non_widgets.filter_map do |association_name|
            sync_callback_class = WorkItem.sync_callback_class(association_name)
            next if sync_callback_class.nil?

            data_handler = sync_callback_class.new(
              work_item: work_item,
              target_work_item: nil,
              current_user: current_user,
              params: params
            )
            data_handler.post_move_cleanup
          end
        end

        def cleanup_work_item
          close_service = Issues::CloseService.new(container: work_item.namespace, current_user: current_user)
          close_service.execute(work_item, notifications: false, system_note: true)
        end
      end
    end
  end
end
