# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Milestone < Base
        def before_create
          # set milestone, e.g.
          # target_work_item.milestone_id = work_item.milestone_id
          # todo system notes for removed/not copied milestone?
        end

        def post_move_cleanup
          # do it
        end
      end
    end
  end
end
