module Notes
  class DiffPositionUpdateService < BaseService
    def execute(note)
      new_position = tracer.trace(note.position)

      # Don't update the position if the type doesn't match, since that means
      # the diff line commented on was changed, and the comment is now outdated
      old_position = note.position
      if new_position &&
          new_position != old_position &&
          new_position.type == old_position.type

        note.position = new_position
      end

      note
    end

    private

    def tracer
      @tracer ||= Gitlab::Diff::PositionTracer.new(
        repository: project.repository,
        old_diff_refs: params[:old_diff_refs],
        new_diff_refs: params[:new_diff_refs],
        paths: params[:paths]
      )
    end
  end
end
