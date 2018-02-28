module API
  module Helpers
    module NotesHelpers
      def update_note(noteable, note_id)
        note = noteable.notes.find(params[:note_id])

        authorize! :admin_note, note

        opts = {
          note: params[:body]
        }
        parent = noteable_parent(noteable)
        project = parent if parent.is_a?(Project)

        note = ::Notes::UpdateService.new(project, current_user, opts).execute(note)

        if note.valid?
          present note, with: Entities::Note
        else
          bad_request!("Failed to save note #{note.errors.messages}")
        end
      end

      def delete_note(noteable, note_id)
        note = noteable.notes.find(note_id)

        authorize! :admin_note, note

        parent = noteable_parent(noteable)
        project = parent if parent.is_a?(Project)
        destroy_conditionally!(note) do |note|
          ::Notes::DestroyService.new(project, current_user).execute(note)
        end
      end

      def get_note(noteable, note_id)
        note = noteable.notes.with_metadata.find(params[:note_id])
        can_read_note = can?(current_user, noteable_read_ability_name(noteable), noteable) && !note.cross_reference_not_visible_for?(current_user)

        if can_read_note
          present note, with: Entities::Note
        else
          not_found!("Note")
        end
      end

      def noteable_read_ability_name(noteable)
        "read_#{noteable.class.to_s.underscore}".to_sym
      end

      def find_noteable(parent, noteables_str, noteable_id)
        public_send("find_#{parent}_#{noteables_str.singularize}", noteable_id) # rubocop:disable GitlabSecurity/PublicSend
      end

      def noteable_parent(noteable)
        public_send("user_#{noteable.class.parent_class.to_s.underscore}") # rubocop:disable GitlabSecurity/PublicSend
      end

      def create_note(noteable, opts)
        noteables_str = noteable.model_name.to_s.underscore.pluralize

        return not_found!(noteables_str) unless can?(current_user, noteable_read_ability_name(noteable), noteable)

        authorize! :create_note, noteable

        parent = noteable_parent(noteable)
        if opts[:created_at]
          opts.delete(:created_at) unless current_user.admin? || parent.owner == current_user
        end

        project = parent if parent.is_a?(Project)
        ::Notes::CreateService.new(project, current_user, opts).execute
      end
    end
  end
end
