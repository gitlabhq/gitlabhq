# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class TimeTracking < Base
        def after_save_commit
          # copy time tracking data, e.g.
          # WorkItems::CopyTimelogsWorker.perform_async(work_item_id, target_work_item_id)
        end

        def post_move_cleanup
          # do it
        end
      end
    end
  end
end
