# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class LinkedItems < Base
        def after_save_commit
          # copy LinkedItems
        end

        def post_move_cleanup
          # do it
        end
      end
    end
  end
end
