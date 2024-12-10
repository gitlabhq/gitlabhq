# frozen_string_literal: true

module API
  module Helpers
    module NotesHelpers
      include ::RendersNotes

      def self.feature_category_per_noteable_type
        {
          Issue => :team_planning,
          MergeRequest => :code_review_workflow,
          Snippet => :source_code_management
        }
      end

      def update_note(noteable, note_id)
        note = noteable.notes.find(note_id)

        authorize! :admin_note, note

        opts = {
          note: params[:body],
          confidential: params[:confidential]
        }.compact
        parent = noteable_parent(noteable)
        project = parent if parent.is_a?(Project)

        note = ::Notes::UpdateService.new(project, current_user, opts).execute(note)

        process_note_creation_result(note) do
          present note, with: Entities::Note
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
        note = noteable.notes.with_metadata.find(note_id)
        can_read_note = note.readable_by?(current_user)

        if can_read_note
          present note, with: Entities::Note
        else
          not_found!("Note")
        end
      end

      def noteable_read_ability_name(noteable)
        "read_#{ability_name(noteable)}".to_sym
      end

      def ability_name(noteable)
        if noteable.respond_to?(:to_ability_name)
          noteable.to_ability_name
        else
          noteable.class.to_s.underscore
        end
      end

      def find_noteable(noteable_type, noteable_id)
        params = finder_params_by_noteable_type_and_id(noteable_type, noteable_id)

        noteable = NotesFinder.new(current_user, params).target

        # Checking `read_note` permission here, because API code does not seem to use NoteFinder to find notes,
        # but rather pulls notes directly through notes association, so there is no chance to check read_note
        # permission at service level. With WorkItem model we need to make sure that it has WorkItem::Widgets::Note
        # available in order to access notes.
        noteable = nil unless can_read_notes?(noteable)
        noteable || not_found!(noteable_type)
      end

      def finder_params_by_noteable_type_and_id(type, id)
        target_type = type.name.underscore
        { target_type: target_type }.tap do |h|
          if %w[issue merge_request].include?(target_type)
            h[:target_iid] = id
          else
            h[:target_id] = id
          end

          add_parent_to_finder_params(h, type)
        end
      end

      def add_parent_to_finder_params(finder_params, noteable_type)
        finder_params[:project] = user_project
      end

      def noteable_parent(noteable)
        public_send("user_#{noteable.class.parent_class.to_s.underscore}") # rubocop:disable GitlabSecurity/PublicSend
      end

      def create_note(noteable, opts)
        disable_query_limiting
        authorize!(:create_note, noteable)

        parent = noteable_parent(noteable)

        opts.delete(:created_at) unless current_user.can?(:set_note_created_at, noteable)

        opts[:updated_at] = opts[:created_at] if opts[:created_at]

        project = parent if parent.is_a?(Project)
        ::Notes::CreateService.new(project, current_user, opts).execute
      end

      def process_note_creation_result(note, &block)
        quick_action_status = note.quick_actions_status

        if quick_action_status&.commands_only? && quick_action_status.success?
          status 202
          present note, with: Entities::NoteCommands
        elsif note.errors.present?
          bad_request!("Note #{note.errors.messages}")
        elsif note.persisted?
          yield
        elsif quick_action_status&.error?
          bad_request!(quick_action_status.error_messages.join(', '))
        end
      end

      def resolve_discussion(noteable, discussion_id, resolved)
        discussion = noteable.find_discussion(discussion_id)

        forbidden! unless discussion.can_resolve?(current_user)

        if resolved
          parent = noteable_parent(noteable)
          ::Discussions::ResolveService.new(parent, current_user, one_or_more_discussions: discussion).execute
        else
          ::Discussions::UnresolveService.new(discussion, current_user).execute
        end

        present discussion, with: Entities::Discussion
      end

      def disable_query_limiting
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/211538')
      end

      private

      def can_read_notes?(noteable)
        Ability.allowed?(current_user, noteable_read_ability_name(noteable), noteable) &&
          Ability.allowed?(current_user, :read_note, noteable)
      end
    end
  end
end

API::Helpers::NotesHelpers.prepend_mod_with('API::Helpers::NotesHelpers')
