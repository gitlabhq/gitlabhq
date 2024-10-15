# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Designs < Base
        def after_save_commit
          # copy designs
        end

        def post_move_cleanup
          # do it
        end
      end
    end
  end
end
