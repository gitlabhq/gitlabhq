# frozen_string_literal: true

module Notes
  class CreateService < ::Notes::BaseService
    # rubocop:disable Metrics/CyclomaticComplexity
    def execute
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
      quick_actions_service = QuickActionsService.new(project, current_user)

      if quick_actions_service.supported?(note)
        content, update_params, message = quick_actions_service.execute(note, quick_action_options)

        only_commands = content.empty?

        note.note = content
      end

      note.run_after_commit do
        # Finish the harder work in the background
        NewNoteWorker.perform_async(note.id)
      end

      note_saved = note.with_transaction_returning_status do
        !only_commands && note.save && note.store_mentions!
      end

      if note_saved
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
    # rubocop:enable Metrics/CyclomaticComplexity

    private

    # EE::Notes::CreateService would override this method
    def quick_action_options
      { merge_request_diff_head_sha: params[:merge_request_diff_head_sha] }
    end

    def tracking_data_for(note)
      label = Gitlab.ee? && note.author == User.visual_review_bot ? 'anonymous_visual_review_note' : 'note'

      {
        label: label,
        value: note.id
      }
    end
  end
end

Notes::CreateService.prepend_if_ee('EE::Notes::CreateService')
