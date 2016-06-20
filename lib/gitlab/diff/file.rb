module Gitlab
  module Diff
    class File
      attr_reader :diff, :repository, :diff_refs

      delegate :new_file, :deleted_file, :renamed_file,
        :old_path, :new_path, to: :diff, prefix: false

      def initialize(diff, repository:, diff_refs: nil)
        @diff = diff
        @repository = repository
        @diff_refs = diff_refs
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

      # Array of Gitlab::Diff::Line objects
      def diff_lines
        @lines ||= Gitlab::Diff::Parser.new.parse(raw_diff.each_line).to_a
      end

      def highlighted_diff_lines
        @highlighted_diff_lines ||= Gitlab::Diff::Highlight.new(self, repository: self.repository).highlight
      end

      def parallel_diff_lines
        @parallel_diff_lines ||= Gitlab::Diff::ParallelDiff.new(self).parallelize
      end

      def mode_changed?
        !!(diff.a_mode && diff.b_mode && diff.a_mode != diff.b_mode)
      end

      def parser
        Gitlab::Diff::Parser.new
      end

      def raw_diff
        diff.diff.to_s
      end

      def next_line(index)
        diff_lines[index + 1]
      end

      def prev_line(index)
        if index > 0
          diff_lines[index - 1]
        end
      end

      def file_path
        new_path.presence || old_path.presence
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
