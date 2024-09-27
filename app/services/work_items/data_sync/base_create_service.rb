# frozen_string_literal: true

module WorkItems
  module DataSync
    # This is a altered version of the WorkItem::CreateService. This overwrites the `initialize_callbacks!`
    # and replaces the callbacks called by `WorkItem::CreateService` to setup data sync related callbacks which
    # are used to copy data from the original work item to the target work item.
    class BaseCreateService < ::WorkItems::CreateService
      attr_reader :original_work_item, :sync_data_mapping

      def initialize(original_work_item:, **kwargs)
        super(**kwargs)

        @original_work_item = original_work_item
      end

      def initialize_callbacks!(work_item)
        @callbacks = work_item.widgets.filter_map do |widget|
          sync_data_callback_class = widget.class.sync_data_callback_class
          next if sync_data_callback_class.nil?

          sync_data_callback_class.new(
            work_item: @original_work_item,
            target_work_item: work_item,
            widget: widget,
            current_user: current_user,
            params: {}
          )
        end
      end
    end
  end
end
