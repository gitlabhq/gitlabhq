module Gitlab
  module Diff
    class File
      attr_reader :diff, :repository, :diff_refs, :fallback_diff_refs

      delegate :new_file?, :deleted_file?, :renamed_file?,
        :old_path, :new_path, :a_mode, :b_mode, :mode_changed?,
        :submodule?, :too_large?, :collapsed?, to: :diff, prefix: false

      def initialize(diff, repository:, diff_refs: nil, fallback_diff_refs: nil)
        @diff = diff
        @repository = repository
        @diff_refs = diff_refs
        @fallback_diff_refs = fallback_diff_refs
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

      def old_sha
        diff_refs&.base_sha
      end

      def new_sha
        diff_refs&.head_sha
      end

      def new_content_sha
        return if deleted_file?
        return @new_content_sha if defined?(@new_content_sha)

        refs = diff_refs || fallback_diff_refs
        @new_content_sha = refs&.head_sha
      end

      def new_content_commit
        return @new_content_commit if defined?(@new_content_commit)

        sha = new_content_commit
        @new_content_commit = repository.commit(sha) if sha
      end

      def old_content_sha
        return if new_file?
        return @old_content_sha if defined?(@old_content_sha)

        refs = diff_refs || fallback_diff_refs
        @old_content_sha = refs&.base_sha
      end

      def old_content_commit
        return @old_content_commit if defined?(@old_content_commit)

        sha = old_content_sha
        @old_content_commit = repository.commit(sha) if sha
      end

      def new_blob
        return @new_blob if defined?(@new_blob)

        sha = new_content_sha
        return @new_blob = nil unless sha

        @new_blob = repository.blob_at(sha, file_path)
      end

      def old_blob
        return @old_blob if defined?(@old_blob)

        sha = old_content_sha
        return @old_blob = nil unless sha

        @old_blob = repository.blob_at(sha, old_path)
      end

      def content_sha
        new_content_sha || old_content_sha
      end

      def content_commit
        new_content_commit || old_content_commit
      end

      def blob
        new_blob || old_blob
      end

      attr_writer :highlighted_diff_lines

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

      def file_identifier
        "#{file_path}-#{new_file?}-#{deleted_file?}-#{renamed_file?}"
      end

      def diffable?
        repository.attributes(file_path).fetch('diff') { true }
      end

      def binary?
        old_blob&.binary? || new_blob&.binary?
      end

      def text?
        !binary?
      end
    end
  end
end
