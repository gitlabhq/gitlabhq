# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Notes < Base
        def after_save_commit
          # copy notes and resource events
          # ::Notes::CopyService.new(current_user, work_item, target_work_item).execute
          # ::Gitlab::Issuable::Clone::CopyResourceEventsService.new(current_user, work_item, target_work_item).execute
        end

        def post_move_cleanup
          # do it
        end
      end
    end
  end
end
