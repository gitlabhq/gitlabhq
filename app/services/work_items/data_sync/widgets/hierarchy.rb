# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Hierarchy < Base
        def after_save_commit
          # copy or relink parent and child items
        end

        def post_move_cleanup
          # do it
        end
      end
    end
  end
end
