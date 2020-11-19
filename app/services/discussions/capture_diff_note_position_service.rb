# frozen_string_literal: true

module Discussions
  class CaptureDiffNotePositionService
    def initialize(merge_request, paths)
      @project = merge_request.project
      @tracer = build_tracer(merge_request, paths)
    end

    def execute(discussion)
      # The service has been implemented for text only
      # We don't need to capture positions for images
      return unless discussion.on_text?

      result = tracer&.trace(discussion.position)
      return unless result

      position = result[:position]
      return unless position

      line_code = position.line_code(project.repository)
      return unless line_code

      # Currently position data is copied across all notes of a discussion
      # It makes sense to store a position only for the first note instead
      # Within the newly introduced table we can start doing just that
      DiffNotePosition.create_or_update_for(discussion.notes.first,
        diff_type: :head,
        position: position,
        line_code: line_code)
    end

    private

    attr_reader :tracer, :project

    def build_tracer(merge_request, paths)
      return if paths.blank?

      old_diff_refs, new_diff_refs = build_diff_refs(merge_request)

      return unless old_diff_refs && new_diff_refs

      Gitlab::Diff::PositionTracer.new(
        project: project,
        old_diff_refs: old_diff_refs,
        new_diff_refs: new_diff_refs,
        paths: paths.uniq)
    end

    def build_diff_refs(merge_request)
      merge_ref_head = merge_request.merge_ref_head
      return unless merge_ref_head

      start_sha, _ = merge_ref_head.parent_ids
      new_diff_refs = Gitlab::Diff::DiffRefs.new(
        base_sha: start_sha,
        start_sha: start_sha,
        head_sha: merge_ref_head.id)

      old_diff_refs = merge_request.diff_refs

      return if new_diff_refs == old_diff_refs

      [old_diff_refs, new_diff_refs]
    end
  end
end
