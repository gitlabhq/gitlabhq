# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      # Endpoints mounting this module must mount Authorization and NotesHelpers too.
      module NoteCreation
        extend Grape::API::Helpers

        params :note_create_params do
          requires :work_item_iid, type: Integer, desc: 'The internal ID of the work item'
          requires :body, type: String, desc: 'The content of a note'
          optional :internal, type: Boolean, desc: 'Internal note flag, default is false'
          optional :created_at, type: String, desc: 'The creation date of the note'
        end

        def create_work_item_note(parent_work_item, type: nil, in_reply_to_discussion_id: nil, &block)
          authorize_note_creation!(parent_work_item)
          create_authorized_work_item_note(parent_work_item, type: type,
            in_reply_to_discussion_id: in_reply_to_discussion_id, &block)
        end

        # Call this before any database lookup so a throttled request costs no queries.
        # check_rate_limit! increments the counter, so it must run exactly once per request.
        def authorize_note_creation!(parent_work_item)
          authorize_work_item_feature!(parent_work_item)
          authorize! :create_note, parent_work_item

          allowlist = Gitlab::CurrentSettings.current_application_settings.notes_create_limit_allowlist
          check_rate_limit! :notes_create, scope: { user: current_user }, users_allowlist: allowlist
        end

        # Expects authorize_note_creation! to have run already.
        def create_authorized_work_item_note(parent_work_item, type: nil, in_reply_to_discussion_id: nil)
          opts = {
            noteable: parent_work_item,
            note: params[:body],
            type: type,
            internal: params[:internal],
            in_reply_to_discussion_id: in_reply_to_discussion_id,
            created_at: params[:created_at],
            scope_validator: ::Gitlab::Auth::ScopeValidator.new(
              current_user, Gitlab::Auth::RequestAuthenticator.new(request)
            )
          }
          opts.delete(:created_at) unless current_user.can?(:set_note_created_at, parent_work_item)
          opts[:updated_at] = opts[:created_at] if opts[:created_at]

          disable_query_limiting

          # Group-level work items have no project; the service accepts nil, as the legacy epic notes path does.
          note = ::Notes::CreateService.new(parent_work_item.project, current_user, opts).execute

          process_note_creation_result(note) { yield note }
        rescue QuickActions::InterpretService::QuickActionsNotAllowedError => e
          forbidden!(e.message)
        end
      end
    end
  end
end
