# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module NoteDeletion
        def delete_work_item_note(parent_work_item, note)
          authorize! :delete_note, note

          destroy_conditionally!(note) do |note_to_destroy|
            # Group-level work items have no project; the service accepts nil, as the GraphQL mutation does.
            ::Notes::DestroyService.new(parent_work_item.project, current_user).execute(note_to_destroy)
          end
        end
      end
    end
  end
end
