# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class TimeTracking < Base
        def before_create
          return unless target_work_item.get_widget(:time_tracking)

          target_work_item.time_estimate = work_item.time_estimate
        end

        def after_save_commit
          return unless params[:operation] == :move
          return unless target_work_item.get_widget(:time_tracking)
          return if work_item.timelogs.empty?

          WorkItems::CopyTimelogsWorker.perform_async(work_item.id, target_work_item.id)
        end

        def post_move_cleanup
          work_item.timelogs.each_batch(of: BATCH_SIZE) do |timelogs|
            timelogs.delete_all
          end
        end
      end
    end
  end
end
