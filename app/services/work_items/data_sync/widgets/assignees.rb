# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Assignees < Base
        def before_create
          # set assignees, e.g.
          # target_work_item.assignee_ids = work_item.assignee_ids
        end

        def post_move_cleanup
          # do it
        end
      end
    end
  end
end
