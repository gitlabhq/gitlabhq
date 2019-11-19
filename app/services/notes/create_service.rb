# frozen_string_literal: true

module Notes
  class CreateService < ::Notes::BaseService
    def execute
      merge_request_diff_head_sha = params.delete(:merge_request_diff_head_sha)

      note = Notes::BuildService.new(project, current_user, params).execute

      # n+1: https://gitlab.com/gitlab-org/gitlab-foss/issues/37440
      note_valid = Gitlab::GitalyClient.allow_n_plus_1_calls do
        note.valid?
      end

      return note unless note_valid

      # We execute commands (extracted from `params[:note]`) on the noteable
      # **before** we save the note because if the note consists of commands
      # only, there is no need be create a note!
      quick_actions_service = QuickActionsService.new(project, current_user)

      if quick_actions_service.supported?(note)
        options = { merge_request_diff_head_sha: merge_request_diff_head_sha }
        content, update_params, message = quick_actions_service.execute(note, options)

        only_commands = content.empty?

        note.note = content
      end

      note.run_after_commit do
        # Finish the harder work in the background
        NewNoteWorker.perform_async(note.id)
      end

      if !only_commands && note.save
        if note.part_of_discussion? && note.discussion.can_convert_to_discussion?
          note.discussion.convert_to_discussion!(save: true)
        end

        todo_service.new_note(note, current_user)
        clear_noteable_diffs_cache(note)
        Suggestions::CreateService.new(note).execute
        increment_usage_counter(note)

        if Feature.enabled?(:notes_create_service_tracking, project)
          Gitlab::Tracking.event('Notes::CreateService', 'execute', tracking_data_for(note))
        end
      end

      if quick_actions_service.commands_executed_count.to_i > 0
        if update_params.present?
          quick_actions_service.apply_updates(update_params, note)
          note.commands_changes = update_params
        end

        # We must add the error after we call #save because errors are reset
        # when #save is called
        if only_commands
          note.errors.add(:commands_only, message.presence || _('Failed to apply commands.'))
        end
      end

      note
    end

    private

    def tracking_data_for(note)
      label = Gitlab.ee? && note.author == User.visual_review_bot ? 'anonymous_visual_review_note' : 'note'

      {
        label: label,
        value: note.id
      }
    end
  end
end
