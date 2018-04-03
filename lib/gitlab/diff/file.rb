module Gitlab
  module Diff
    class File
      attr_reader :diff, :repository, :diff_refs, :fallback_diff_refs

      delegate :new_file?, :deleted_file?, :renamed_file?,
        :old_path, :new_path, :a_mode, :b_mode, :mode_changed?,
        :submodule?, :expanded?, :too_large?, :collapsed?, :line_count, :has_binary_notice?, to: :diff, prefix: false

      # Finding a viewer for a diff file happens based only on extension and whether the
      # diff file blobs are binary or text, which means 1 diff file should only be matched by 1 viewer,
      # and the order of these viewers doesn't really matter.
      #
      # However, when the diff file blobs are LFS pointers, we cannot know for sure whether the
      # file being pointed to is binary or text. In this case, we match only on
      # extension, preferring binary viewers over text ones if both exist, since the
      # large files referred to in "Large File Storage" are much more likely to be
      # binary than text.
      RICH_VIEWERS = [
        DiffViewer::Image
      ].sort_by { |v| v.binary? ? 0 : 1 }.freeze

      def initialize(diff, repository:, diff_refs: nil, fallback_diff_refs: nil)
        @diff = diff
        @repository = repository
        @diff_refs = diff_refs
        @fallback_diff_refs = fallback_diff_refs

        # Ensure items are collected in the the batch
        new_blob_lazy
        old_blob_lazy
      end

      def position(position_marker, position_type: :text)
        return unless diff_refs

        data = {
          diff_refs: diff_refs,
          position_type: position_type.to_s,
          old_path: old_path,
          new_path: new_path
        }

        if position_type == :text
          data.merge!(text_position_properties(position_marker))
        else
          data.merge!(image_position_properties(position_marker))
        end

        Position.new(data)
      end

      def line_code(line)
        return if line.meta?

        Gitlab::Git.diff_line_code(file_path, line.new_pos, line.old_pos)
      end

      def line_for_line_code(code)
        diff_lines.find { |line| line_code(line) == code }
      end

      def line_for_position(pos)
        return nil unless pos.position_type == 'text'

        diff_lines.find { |line| line.old_line == pos.old_line && line.new_line == pos.new_line }
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

      def old_content_sha
        return if new_file?
        return @old_content_sha if defined?(@old_content_sha)

        refs = diff_refs || fallback_diff_refs
        @old_content_sha = refs&.base_sha
      end

      def new_blob
        new_blob_lazy&.itself
      end

      def old_blob
        old_blob_lazy&.itself
      end

      def content_sha
        new_content_sha || old_content_sha
      end

      def blob
        new_blob || old_blob
      end

      attr_writer :highlighted_diff_lines

      # Array of Gitlab::Diff::Line objects
      def diff_lines
        @diff_lines ||=
          Gitlab::Diff::Parser.new.parse(raw_diff.each_line, diff_file: self).to_a
      end

      def highlighted_diff_lines
        @highlighted_diff_lines ||=
          Gitlab::Diff::Highlight.new(self, repository: self.repository).highlight
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
        has_binary_notice? || try_blobs(:binary?)
      end

      def text?
        !binary?
      end

      def external_storage_error?
        try_blobs(:external_storage_error?)
      end

      def stored_externally?
        try_blobs(:stored_externally?)
      end

      def external_storage
        try_blobs(:external_storage)
      end

      def content_changed?
        return blobs_changed? if diff_refs
        return false if new_file? || deleted_file? || renamed_file?

        text? && diff_lines.any?
      end

      def different_type?
        old_blob && new_blob && old_blob.binary? != new_blob.binary?
      end

      def size
        valid_blobs.map(&:size).sum
      end

      def raw_size
        valid_blobs.map(&:raw_size).sum
      end

      def raw_binary?
        try_blobs(:raw_binary?)
      end

      def raw_text?
        !raw_binary? && !different_type?
      end

      def simple_viewer
        @simple_viewer ||= simple_viewer_class.new(self)
      end

      def rich_viewer
        return @rich_viewer if defined?(@rich_viewer)

        @rich_viewer = rich_viewer_class&.new(self)
      end

      def rendered_as_text?(ignore_errors: true)
        simple_viewer.is_a?(DiffViewer::Text) && (ignore_errors || simple_viewer.render_error.nil?)
      end

      private

      # We can't use Object#try because Blob doesn't inherit from Object, but
      # from BasicObject (via SimpleDelegator).
      def try_blobs(meth)
        old_blob&.public_send(meth) || new_blob&.public_send(meth)
      end

      def valid_blobs
        [old_blob, new_blob].compact
      end

      def text_position_properties(line)
        { old_line: line.old_line, new_line: line.new_line }
      end

      def image_position_properties(image_point)
        image_point.to_h
      end

      def blobs_changed?
        old_blob && new_blob && old_blob.id != new_blob.id
      end

      def new_blob_lazy
        return unless new_content_sha

        Blob.lazy(repository.project, new_content_sha, file_path)
      end

      def old_blob_lazy
        return unless old_content_sha

        Blob.lazy(repository.project, old_content_sha, old_path)
      end

      def simple_viewer_class
        return DiffViewer::NotDiffable unless diffable?

        if content_changed?
          if raw_text?
            DiffViewer::Text
          else
            DiffViewer::NoPreview
          end
        elsif new_file?
          if raw_text?
            DiffViewer::Text
          else
            DiffViewer::Added
          end
        elsif deleted_file?
          if raw_text?
            DiffViewer::Text
          else
            DiffViewer::Deleted
          end
        elsif renamed_file?
          DiffViewer::Renamed
        elsif mode_changed?
          DiffViewer::ModeChanged
        else
          DiffViewer::NoPreview
        end
      end

      def rich_viewer_class
        viewer_class_from(RICH_VIEWERS)
      end

      def viewer_class_from(classes)
        return unless diffable?
        return if different_type? || external_storage_error?
        return unless new_file? || deleted_file? || content_changed?

        verify_binary = !stored_externally?

        classes.find { |viewer_class| viewer_class.can_render?(self, verify_binary: verify_binary) }
      end
    end
  end
end
