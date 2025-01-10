# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class LinkedResources < Base
        def after_save_commit
          # Placeholder, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174793#note_2246113161
        end

        def post_move_cleanup
          # do it
        end
      end
    end
  end
end
