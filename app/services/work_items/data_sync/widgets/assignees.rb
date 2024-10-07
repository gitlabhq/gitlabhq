# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Assignees < Base
        def before_create
          return unless target_work_item.get_widget(:assignees)

          target_work_item.assignee_ids = work_item.assignee_ids
        end

        def post_move_cleanup
          work_item.assignee_ids = []
        end
      end
    end
  end
end
