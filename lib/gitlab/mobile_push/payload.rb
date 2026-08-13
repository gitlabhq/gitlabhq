# frozen_string_literal: true

module Gitlab
  module MobilePush
    # Builds the APNs notification content for a todo. The copy mirrors the
    # GitLab mobile app's to-do list (`Todo.actionText` / `showAuthor` in the
    # app) so pushes read exactly like the rows they open.
    #
    # In :id_only mode (the subscription's payload_mode) no user content
    # leaves the instance: the alert is a fixed generic sentence, the
    # `gitlab` dict carries identifiers only, and `mutable-content` is set
    # so the app's notification service extension can fetch and render the
    # real content on-device.
    class Payload
      GENERIC_BODY = 'You have a new to-do'
      ACTION_PHRASES = {
        'assigned' => 'assigned you.',
        'review_requested' => 'requested a review.',
        'mentioned' => 'mentioned you.',
        'directly_addressed' => 'mentioned you.',
        'build_failed' => 'The pipeline failed.',
        'marked' => 'added a to-do item.',
        'approval_required' => 'created a merge request you can approve.',
        'added_approver' => 'created a merge request you can approve.',
        'unmergeable' => 'Could not merge.',
        'merge_train_removed' => 'Removed from Merge Train.',
        'review_submitted' => 'reviewed your merge request.',
        'member_access_requested' => 'has requested access.',
        'okr_checkin_requested' => 'requested an OKR update.',
        'ssh_key_expired' => 'Your SSH key has expired.',
        'ssh_key_expiring_soon' => 'Your SSH key is expiring soon.'
      }.freeze

      # Actions whose phrase is a standalone sentence. The app hides the
      # author for these (`showAuthor == false`), so the body does too.
      AUTHORLESS_ACTIONS = %w[
        build_failed
        unmergeable
        merge_train_removed
        ssh_key_expired
        ssh_key_expiring_soon
      ].freeze

      def initialize(todo, mode: :full)
        @todo = todo
        @mode = mode.to_sym
      end

      def id_only?
        mode == :id_only
      end

      def title
        return if id_only?

        target_title.presence || reference
      end

      def subtitle
        return if id_only?

        [full_path, reference].compact_blank.join(' · ')
      end

      def body
        return GENERIC_BODY if id_only?
        return action_phrase if AUTHORLESS_ACTIONS.include?(action)

        [todo.author_name, action_phrase].compact_blank.join(' ')
      end

      def badge
        todo.user.todos_pending_count
      end

      def thread_id
        return if id_only?

        "#{full_path}#{reference}"
      end

      def collapse_id
        "todo-#{todo.id}"
      end

      def mutable_content?
        id_only?
      end

      def gitlab_data
        return { version: 1, type: 'todo', todo_id: todo.id, user_id: todo.user_id } if id_only?

        {
          version: 1,
          type: 'todo',
          todo_id: todo.id,
          user_id: todo.user_id,
          action: action,
          target_type: todo.target_type,
          project_path: full_path,
          iid: todo.target.try(:iid),
          target_url: todo.target_url,
          note_id: todo.note_id
        }
      end

      private

      attr_reader :todo, :mode

      def action
        todo.action_name.to_s
      end

      def action_phrase
        ACTION_PHRASES.fetch(action) { "#{action.tr('_', ' ')}." }
      end

      def target_title
        todo.target.try(:title) || todo.target.try(:name)
      end

      def reference
        todo.target_reference.to_s
      end

      def full_path
        todo.resource_parent&.full_path
      end
    end
  end
end
