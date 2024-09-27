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
          @work_item.widgets.each do |widget|
            handler_class = widget.sync_data_callback_class
            data_handler = handler_class&.new(
              work_item: work_item,
              target_work_item: nil,
              widget: widget,
              current_user: current_user,
              params: params
            )
            data_handler&.post_move_cleanup
          end
        end
      end
    end
  end
end
