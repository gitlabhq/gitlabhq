# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Participants < Base
        def after_save_commit
          # copy user mentions
        end

        def post_move_cleanup
          # do it
        end
      end
    end
  end
end
