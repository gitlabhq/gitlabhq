# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Base < ::WorkItems::Callbacks::Base
        attr_reader :work_item, :target_work_item, :current_user

        BATCH_SIZE = 100

        def initialize(work_item:, target_work_item:, current_user:, params: {})
          @work_item = work_item
          @target_work_item = target_work_item
          @current_user = current_user
          @params = params
        end

        # IMPORTANT: This is a callback that is called by `BaseCleanupDataService` from `DataSync::MoveService` after
        # the work item is moved to the target namespace to delete the original work item data. That is because we have
        # to implement `MoveService` as `copy` to destination & `delete` from source.
        #
        # Has to be implemented in the specific widget class or it can be an empty implementation if it does not need to
        # cleanup any data on the original work item
        def post_move_cleanup; end
      end
    end
  end
end
