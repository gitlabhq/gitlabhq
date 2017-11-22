module Notes
  class CreateService < ::BaseService
    def execute
      merge_request_diff_head_sha = params.delete(:merge_request_diff_head_sha)

      note = Notes::BuildService.new(project, current_user, params).execute

      # n+1: https://gitlab.com/gitlab-org/gitlab-ce/issues/37440
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
        content, commands, results = quick_actions_service.extract_commands(note, options)

        only_quick_actions = content.empty? && (commands.any? || results.any?)

        note.note = content
      end

      note.run_after_commit do
        # Finish the harder work in the background
        NewNoteWorker.perform_async(note.id)
      end

      if !only_quick_actions && note.save
        todo_service.new_note(note, current_user)
      end

      quick_actions_service.execute(commands, note)

      note.quick_actions_commands = commands
      note.quick_actions_results = results

      note
    end
  end
end
