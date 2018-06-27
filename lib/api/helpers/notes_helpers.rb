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

      def resolve_note(noteable, note_id, resolved)
        note = noteable.notes.find(note_id)

        authorize! :resolve_note, note

        bad_request!("Note is not resolvable") unless note.resolvable?

        if resolved
          parent = noteable_parent(noteable)
          ::Notes::ResolveService.new(parent, current_user).execute(note)
        else
          note.unresolve!
        end

        present note, with: Entities::Note
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
        can_read_note = !note.cross_reference_not_visible_for?(current_user)

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
        noteable = public_send("find_#{parent}_#{noteables_str.singularize}", noteable_id) # rubocop:disable GitlabSecurity/PublicSend

        readable =
          if noteable.is_a?(Commit)
            # for commits there is not :read_commit policy, check if user
            # has :read_note permission on the commit's project
            can?(current_user, :read_note, user_project)
          else
            can?(current_user, noteable_read_ability_name(noteable), noteable)
          end

        return not_found!(noteables_str) unless readable

        noteable
      end

      def noteable_parent(noteable)
        public_send("user_#{noteable.class.parent_class.to_s.underscore}") # rubocop:disable GitlabSecurity/PublicSend
      end

      def create_note(noteable, opts)
        policy_object = noteable.is_a?(Commit) ? user_project : noteable
        authorize!(:create_note, policy_object)

        parent = noteable_parent(noteable)

        if opts[:created_at]
          opts.delete(:created_at) unless
            current_user.admin? || parent.owned_by?(current_user)
        end

        project = parent if parent.is_a?(Project)
        ::Notes::CreateService.new(project, current_user, opts).execute
      end

      def resolve_discussion(noteable, discussion_id, resolved)
        discussion = noteable.find_discussion(discussion_id)

        forbidden! unless discussion.can_resolve?(current_user)

        if resolved
          parent = noteable_parent(noteable)
          ::Discussions::ResolveService.new(parent, current_user, merge_request: noteable).execute(discussion)
        else
          discussion.unresolve!
        end

        present discussion, with: Entities::Discussion
      end
    end
  end
end
