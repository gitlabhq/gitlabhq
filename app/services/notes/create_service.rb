# frozen_string_literal: true

module Notes
  class CreateService < ::Notes::BaseService
    include IncidentManagement::UsageData

    def execute(skip_capture_diff_note_position: false, skip_merge_status_trigger: false, skip_set_reviewed: false)
      note = Notes::BuildService.new(project, current_user, params.except(:merge_request_diff_head_sha)).execute

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
        note.run_after_commit do
          # Finish the harder work in the background
          NewNoteWorker.perform_async(note.id)
        end

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
            skip_merge_status_trigger: skip_merge_status_trigger,
            skip_set_reviewed: skip_set_reviewed
          )
        end
      end

      note
    end

    private

    def execute_quick_actions(note)
      return yield(false) unless quick_actions_supported?(note)

      content, update_params, message, command_names = quick_actions_service.execute(note, quick_action_options)
      only_commands = content.empty?
      note.note = content
      note.command_names = command_names

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
      note, skip_capture_diff_note_position: false, skip_merge_status_trigger: false,
      skip_set_reviewed: false)
      todo_service.new_note(note, current_user)
      clear_noteable_diffs_cache(note)
      Suggestions::CreateService.new(note).execute
      increment_usage_counter(note)
      track_event(note, current_user)

      if note.for_merge_request? && note.start_of_discussion?
        set_reviewed(note) unless skip_set_reviewed

        if !skip_capture_diff_note_position && note.diff_note?
          Discussions::CaptureDiffNotePositionService.new(note.noteable, note.diff_file&.paths).execute(note.discussion)
        end

        if !skip_merge_status_trigger && note.to_be_resolved?
          GraphqlTriggers.merge_request_merge_status_updated(note.noteable)
        end
      end
    end

    def do_commands(note, update_params, message, command_names, only_commands)
      return if quick_actions_service.commands_executed_count.to_i == 0

      if update_params.present?
        invalid_message = validate_commands(note, update_params)

        if invalid_message
          note.errors.add(:validation, invalid_message)
          message = invalid_message
        else
          quick_actions_service.apply_updates(update_params, note)
          note.commands_changes = update_params
        end
      end

      # We must add the error after we call #save because errors are reset
      # when #save is called
      if only_commands
        note.errors.add(:commands_only, message.presence || _('Failed to apply commands.'))
        note.errors.add(:command_names, command_names.flatten)
        # Allow consumers to detect problems applying commands
        note.errors.add(:commands, _('Failed to apply commands.')) unless message.present?
      end
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
      track_note_creation_visual_review(note)

      metric_key_path = 'counts.commit_comment'

      Gitlab::Tracking.event(
        'Notes::CreateService',
        'create_commit_comment',
        project: project,
        namespace: project&.namespace,
        user: user,
        label: metric_key_path,
        context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis, key_path: metric_key_path).to_context]
      )
    end

    def tracking_data_for(note)
      label = Gitlab.ee? && note.author == User.visual_review_bot ? 'anonymous_visual_review_note' : 'note'

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
      Feature.enabled?(:ipynbdiff_notes_tracker) && note.respond_to?(:diff_file) && note.diff_file&.ipynb?
    end

    def track_note_creation_in_ipynb(note)
      return unless should_track_ipynb_notes?(note)

      Gitlab::UsageDataCounters::IpynbDiffActivityCounter.note_created(note)
    end

    def track_note_creation_visual_review(note)
      Gitlab::Tracking.event('Notes::CreateService', 'execute', **tracking_data_for(note))
    end

    def set_reviewed(note)
      ::MergeRequests::MarkReviewerReviewedService.new(project: project, current_user: current_user)
        .execute(note.noteable)
    end
  end
end

Notes::CreateService.prepend_mod_with('Notes::CreateService')
