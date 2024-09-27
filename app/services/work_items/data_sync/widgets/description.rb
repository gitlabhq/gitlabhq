# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Description < Base
        def before_create
          # set description, e.g.
          # work_item.description = target_work_item.description
        end

        def post_move_cleanup
          # do it
        end
      end
    end
  end
end
