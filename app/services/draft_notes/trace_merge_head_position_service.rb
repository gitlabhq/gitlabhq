# frozen_string_literal: true

module DraftNotes
  # Retraces draft note positions onto the merge_head diff, in memory only, as merge_head_position (`positions`, what
  # rapid diffs matches on) and an overwritten line_code (what the legacy renderer matches on). Mirrors
  # Discussions::CaptureDiffNotePositionService for published notes.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/590869.
  class TraceMergeHeadPositionService
    include Gitlab::Loggable
    include Gitlab::Utils::StrongMemoize

    # Above this many distinct files, tracing is skipped for the whole collection, since each file adds Gitaly work.
    FILE_LIMIT = 20

    def initialize(merge_request, drafts)
      @merge_request = merge_request
      @drafts = Array.wrap(drafts)
    end

    def execute
      return unless Feature.enabled?(:draft_note_merge_head_line_code, merge_request.project)
      return unless merge_request.diffable_merge_ref?
      return unless tracer

      traceable_drafts.each do |draft, position|
        result = tracer.trace(position)
        next if result.blank? || result[:outdated]

        traced_position = result[:position]
        next unless traced_position

        draft.merge_head_position = traced_position

        line_code = traced_position.line_code(merge_request.project.repository)
        draft.line_code = line_code if line_code
      end
    end

    private

    attr_reader :merge_request, :drafts

    # Same diff_refs Discussions::CaptureDiffNotePositionService builds; duplicated so no shared code path changes.
    def tracer
      paths = trace_paths
      return if paths.blank?

      merge_ref_head = merge_request.merge_ref_head
      return unless merge_ref_head

      start_sha = merge_ref_head.parent_ids.first
      return unless start_sha

      new_diff_refs = Gitlab::Diff::DiffRefs.new(
        base_sha: start_sha,
        start_sha: start_sha,
        head_sha: merge_ref_head.id
      )
      old_diff_refs = merge_request.diff_refs
      return if old_diff_refs.blank? || old_diff_refs == new_diff_refs

      Gitlab::Diff::PositionTracer.new(
        project: merge_request.project,
        old_diff_refs: old_diff_refs,
        new_diff_refs: new_diff_refs,
        paths: paths
      )
    end
    strong_memoize_attr :tracer

    # [[DraftNote, Gitlab::Diff::Position], ...]. Filtering up front keeps untraceable files out of FILE_LIMIT and
    # the tracer's CompareService scope.
    def traceable_drafts
      drafts.filter_map do |draft|
        next unless draft.on_diff?

        position = traceable_position(draft)
        [draft, position] if position
      end
    end
    strong_memoize_attr :traceable_drafts

    # UI drafts carry merge-head refs in original_position and MR refs in `position`; API drafts carry MR refs in
    # both. Prefer original_position, but without the `position` fallback the UI path is a no-op.
    def traceable_position(draft)
      [draft.original_position, draft.position].compact.find do |position|
        position.diff_refs == merge_request.diff_refs
      end
    end

    # All-or-nothing above FILE_LIMIT so every draft behaves the same.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/604420.
    def trace_paths
      paths = traceable_drafts.map { |_draft, position| position.file_path }.uniq
      return paths if paths.size <= FILE_LIMIT

      Gitlab::AppLogger.info(build_structured_payload_labkit(
        message: 'Draft note merge_head line_code tracing skipped: file limit exceeded',
        merge_request_id: merge_request.id,
        project_id: merge_request.project_id,
        commented_file_count: paths.size,
        file_limit: FILE_LIMIT
      ))

      []
    end
  end
end
