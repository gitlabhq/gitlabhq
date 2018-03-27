module Discussions
  class UpdateDiffPositionService < BaseService
    def execute(discussion)
      result = tracer.trace(discussion.position)
      return unless result

      position = result[:position]
      outdated = result[:outdated]

      discussion.notes.each do |note|
        if outdated
          note.change_position = position

          if project.resolve_outdated_diff_discussions?
            note.resolve_without_save(current_user, resolved_by_push: true)
          end
        else
          note.position = position
          note.change_position = nil
        end
      end

      Note.transaction do
        discussion.notes.each do |note|
          Gitlab::Timeless.timeless(note, &:save)
        end

        if outdated && current_user
          SystemNoteService.diff_discussion_outdated(discussion, project, current_user, position)
        end
      end
    end

    private

    def tracer
      @tracer ||= Gitlab::Diff::PositionTracer.new(
        project: project,
        old_diff_refs: params[:old_diff_refs],
        new_diff_refs: params[:new_diff_refs],
        paths: params[:paths]
      )
    end
  end
end
