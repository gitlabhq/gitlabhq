# frozen_string_literal: true

module WorkItems
  module DataSync
    # This is a altered version of the WorkItem::CreateService. This overwrites the `initialize_callbacks!`
    # and replaces the callbacks called by `WorkItem::CreateService` to setup data sync related callbacks which
    # are used to copy data from the original work item to the target work item.
    class BaseCreateService < ::WorkItems::CreateService
      attr_reader :original_work_item, :operation, :sync_data_params

      def initialize(original_work_item:, operation:, **kwargs)
        super(**kwargs)

        @original_work_item = original_work_item
        @operation = operation
        @sync_data_params = params.delete(:sync_data_params) || {}
      end

      def initialize_callbacks!(work_item)
        @callbacks = original_work_item.widgets.filter_map do |widget|
          sync_data_callback_class = widget.class.sync_data_callback_class
          next if sync_data_callback_class.nil?

          callback_params = {}

          if sync_data_callback_class.const_defined?(:ALLOWED_PARAMS)
            callback_params = sync_data_params.slice(*sync_data_callback_class::ALLOWED_PARAMS)
          end

          sync_data_callback_class.new(
            work_item: original_work_item,
            target_work_item: work_item,
            current_user: current_user,
            params: callback_params.merge({ operation: operation })
          )
        end

        @callbacks += WorkItem.non_widgets.filter_map do |association_name|
          sync_callback_class = WorkItem.sync_callback_class(association_name)
          next if sync_callback_class.nil?

          sync_callback_class.new(
            work_item: original_work_item,
            target_work_item: work_item,
            current_user: current_user,
            params: { operation: operation }
          )
        end

        @callbacks
      end
    end
  end
end
