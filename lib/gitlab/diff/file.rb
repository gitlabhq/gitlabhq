module Gitlab
  module Diff
    class File
      attr_reader :diff, :repository, :diff_refs

      delegate :new_file, :deleted_file, :renamed_file,
        :old_path, :new_path, :a_mode, :b_mode,
        :submodule?, :too_large?, :collapsed?, to: :diff, prefix: false

      def initialize(diff, repository:, diff_refs: nil)
        @diff = diff
        @repository = repository
        @diff_refs = diff_refs
      end

      def position(line)
        return unless diff_refs

        Position.new(
          old_path: old_path,
          new_path: new_path,
          old_line: line.old_line,
          new_line: line.new_line,
          diff_refs: diff_refs
        )
      end

      def line_code(line)
        return if line.meta?

        Gitlab::Diff::LineCode.generate(file_path, line.new_pos, line.old_pos)
      end

      def line_for_line_code(code)
        diff_lines.find { |line| line_code(line) == code }
      end

      def line_for_position(pos)
        diff_lines.find { |line| position(line) == pos }
      end

      def position_for_line_code(code)
        line = line_for_line_code(code)
        position(line) if line
      end

      def line_code_for_position(pos)
        line = line_for_position(pos)
        line_code(line) if line
      end

      def content_commit
        return unless diff_refs

        repository.commit(deleted_file ? old_ref : new_ref)
      end

      def old_ref
        diff_refs.try(:base_sha)
      end

      def new_ref
        diff_refs.try(:head_sha)
      end

      attr_writer :diff_lines, :highlighted_diff_lines

      # Array of Gitlab::Diff::Line objects
      def diff_lines
        @diff_lines ||= Gitlab::Diff::Parser.new.parse(raw_diff.each_line).to_a
      end

      def highlighted_diff_lines
        @highlighted_diff_lines ||= Gitlab::Diff::Highlight.new(self, repository: self.repository).highlight
      end

      # Array[<Hash>] with right/left keys that contains Gitlab::Diff::Line objects which text is hightlighted
      def parallel_diff_lines
        @parallel_diff_lines ||= Gitlab::Diff::ParallelDiff.new(self).parallelize
      end

      def mode_changed?
        a_mode && b_mode && a_mode != b_mode
      end

      def raw_diff
        diff.diff.to_s
      end

      def next_line(index)
        diff_lines[index + 1]
      end

      def prev_line(index)
        diff_lines[index - 1] if index > 0
      end

      def paths
        [old_path, new_path].compact
      end

      def file_path
        new_path.presence || old_path
      end

      def added_lines
        diff_lines.count(&:added?)
      end

      def removed_lines
        diff_lines.count(&:removed?)
      end

      def old_blob(commit = content_commit)
        return unless commit

        parent_id = commit.parent_id
        return unless parent_id

        repository.blob_at(parent_id, old_path)
      end

      def blob(commit = content_commit)
        return unless commit

        repository.blob_at(commit.id, file_path)
      end
    end
  end
end
