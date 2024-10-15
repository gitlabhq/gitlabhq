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
          cleanup_work_item_widgets_data
          cleanup_work_item
        end

        private

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

        def cleanup_work_item
          close_service = Issues::CloseService.new(container: work_item.namespace, current_user: current_user)
          close_service.execute(work_item, notifications: false, system_note: true)
        end
      end
    end
  end
end
