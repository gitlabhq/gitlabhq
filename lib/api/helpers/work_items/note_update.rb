# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      # Endpoints mounting this module must mount NotesHelpers too.
      module NoteUpdate
        def update_work_item_note(parent_work_item, note)
          authorize! :update_note, note

          # Group-level work items have no project; the service accepts nil, as the legacy epic notes path does.
          opts = {
            note: params[:body],
            scope_validator: ::Gitlab::Auth::ScopeValidator.new(
              current_user, Gitlab::Auth::RequestAuthenticator.new(request)
            )
          }
          note = ::Notes::UpdateService.new(parent_work_item.project, current_user, opts).execute(note)

          process_note_creation_result(note) do
            present note, with: ::API::Entities::Note, current_user: current_user
          end
        rescue QuickActions::InterpretService::QuickActionsNotAllowedError => e
          forbidden!(e.message)
        end
      end
    end
  end
end
