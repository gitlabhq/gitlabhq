module Notes
  class DiffPositionUpdateService < BaseService
    def execute(note)
      results = tracer.trace(note.position)
      return unless results

      position = results[:position]
      outdated = results[:outdated]

      if outdated
        note.change_position = position

        if note.persisted? && current_user
          SystemNoteService.diff_discussion_outdated(note.to_discussion, project, current_user, position)
        end
      else
        note.position = position
        note.change_position = nil
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
