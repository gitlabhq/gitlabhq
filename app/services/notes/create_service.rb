# frozen_string_literal: true

module Notes
  class CreateService < ::Notes::BaseService
    include IncidentManagement::UsageData

    def execute(
      skip_capture_diff_note_position: false, skip_merge_status_trigger: false, executing_user: nil,
      importing: false)
      note = build_note(executing_user)

      # n+1: https://gitlab.com/gitlab-org/gitlab-foss/issues/37440
      note_valid = Gitlab::GitalyClient.allow_n_plus_1_calls do
        # We may set errors manually in Notes::BuildService for this reason
        # we also need to check for already existing errors.
        note.errors.empty? && note.valid?
      end

      return note unless note_valid

      # We execute commands (extracted from `params[:note]`) on the noteable
      # **before** we save the note because if the note consists of commands
      # only, there is no need be create a note!

      execute_quick_actions(note) do |only_commands|
        note.check_for_spam(action: :create, user: current_user) if check_for_spam?(only_commands)

        after_commit(note) unless importing

        note_saved = note.with_transaction_returning_status do
          break false if only_commands

          note.save.tap do
            update_discussions(note)
          end
        end

        if note_saved
          when_saved(
            note,
            skip_capture_diff_note_position: skip_capture_diff_note_position,
            skip_merge_status_trigger: skip_merge_status_trigger
          )
        end
      end

      note
    end

    private

    def build_note(executing_user)
      Notes::BuildService
        .new(project, current_user, params.except(:merge_request_diff_head_sha))
        .execute(executing_user: executing_user)
    end

    def check_for_spam?(only_commands)
      !only_commands
    end

    def after_commit(note)
      note.run_after_commit do
        # Complete more expensive operations like sending
        # notifications and post processing in a background worker.
        NewNoteWorker.perform_async(note.id)
      end
    end

    def execute_quick_actions(note)
      return yield(false) unless quick_actions_supported?(note)

      content, update_params, message, command_names = quick_actions_service.execute(note, quick_action_options)
      only_commands = content.empty?
      note.note = content

      yield(only_commands)

      do_commands(note, update_params, message, command_names, only_commands)
    end

    def quick_actions_supported?(note)
      quick_actions_service.supported?(note)
    end

    def quick_actions_service
      @quick_actions_service ||= QuickActionsService.new(project, current_user)
    end

    def update_discussions(note)
      # Ensure that individual notes that are promoted into discussions are
      # updated in a transaction with the note creation to avoid inconsistencies:
      # https://gitlab.com/gitlab-org/gitlab/-/issues/301237
      if note.part_of_discussion? && note.discussion.can_convert_to_discussion?
        note.discussion.convert_to_discussion!.save
        note.clear_memoization(:discussion)
      end
    end

    def when_saved(
      note, skip_capture_diff_note_position: false, skip_merge_status_trigger: false)
      todo_service.new_note(note, current_user)
      clear_noteable_diffs_cache(note)
      Suggestions::CreateService.new(note).execute
      increment_usage_counter(note)
      track_event(note, current_user)

      if note.for_merge_request? && note.start_of_discussion?
        if !skip_capture_diff_note_position && note.diff_note?
          Discussions::CaptureDiffNotePositionService.new(note.noteable, note.diff_file&.paths).execute(note.discussion)
        end

        if !skip_merge_status_trigger && note.to_be_resolved?
          GraphqlTriggers.merge_request_merge_status_updated(note.noteable)
        end
      end
    end

    def do_commands(note, update_params, message, command_names, only_commands)
      status = ::Notes::QuickActionsStatus.new(
        command_names: command_names&.flatten,
        commands_only: only_commands)
      status.add_message(message)

      note.quick_actions_status = status

      return if quick_actions_service.commands_executed_count.to_i == 0

      update_error = quick_actions_update_errors(note, update_params)
      if update_error
        note.errors.add(:validation, update_error)
        status.add_error(update_error)
      end

      status.add_error(_('Failed to apply commands.')) if only_commands && message.blank?
    end

    def quick_actions_update_errors(note, params)
      return unless params.present?

      invalid_message = validate_commands(note, params)
      return invalid_message if invalid_message

      service_response = quick_actions_service.apply_updates(params, note)
      note.commands_changes = params
      return if service_response.success?

      service_response.message.join(', ')
    end

    def quick_action_options
      {
        merge_request_diff_head_sha: params[:merge_request_diff_head_sha],
        review_id: params[:review_id]
      }
    end

    def validate_commands(note, update_params)
      if invalid_reviewers?(update_params)
        "Reviewers #{note.noteable.class.max_number_of_assignees_or_reviewers_message}"
      elsif invalid_assignees?(update_params)
        "Assignees #{note.noteable.class.max_number_of_assignees_or_reviewers_message}"
      end
    end

    def invalid_reviewers?(update_params)
      if update_params.key?(:reviewer_ids)
        possible_reviewers = update_params[:reviewer_ids]&.uniq&.size

        possible_reviewers > ::Issuable::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS
      else
        false
      end
    end

    def invalid_assignees?(update_params)
      if update_params.key?(:assignee_ids)
        possible_assignees = update_params[:assignee_ids]&.uniq&.size

        possible_assignees > ::Issuable::MAX_NUMBER_OF_ASSIGNEES_OR_REVIEWERS
      else
        false
      end
    end

    def track_event(note, user)
      track_note_creation_usage_for_issues(note) if note.for_issue?
      track_note_creation_usage_for_merge_requests(note) if note.for_merge_request?
      track_incident_action(user, note.noteable, 'incident_comment') if note.for_issue?
      track_note_creation_in_ipynb(note)
    end

    def tracking_data_for(note)
      label = Gitlab.ee? && note.author == Users::Internal.visual_review_bot ? 'anonymous_visual_review_note' : 'note'

      {
        label: label,
        value: note.id
      }
    end

    def track_note_creation_usage_for_issues(note)
      Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_comment_added_action(
        author: note.author,
        project: project
      )
    end

    def track_note_creation_usage_for_merge_requests(note)
      Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter.track_create_comment_action(note: note)
    end

    def should_track_ipynb_notes?(note)
      note.respond_to?(:diff_file) && note.diff_file&.ipynb?
    end

    def track_note_creation_in_ipynb(note)
      return unless should_track_ipynb_notes?(note)

      Gitlab::UsageDataCounters::IpynbDiffActivityCounter.note_created(note)
    end
  end
end

Notes::CreateService.prepend_mod_with('Notes::CreateService')
