# frozen_string_literal: true

# Defines a specific location, identified by paths line numbers and image coordinates,
# within a specific diff, identified by start, head and base commit ids.
module Gitlab
  module Diff
    class Position
      attr_accessor :formatter

      delegate :old_path,
        :new_path,
        :base_sha,
        :start_sha,
        :head_sha,
        :old_line,
        :new_line,
        :width,
        :height,
        :x,
        :y,
        :line_range,
        :position_type,
        :ignore_whitespace_change, to: :formatter

      # A position can belong to a text line or to an image coordinate
      # it depends of the position_type argument.
      # Text position will have: new_line and old_line
      # Image position will have: width, height, x, y
      def initialize(attrs = {})
        @formatter = get_formatter_class(attrs[:position_type]).new(attrs)
      end

      # `Gitlab::Diff::Position` objects are stored as serialized attributes in
      # `DiffNote`, which use YAML to encode and decode objects.
      # `#init_with` and `#encode_with` can be used to customize the en/decoding
      # behavior. In this case, we override these to prevent memoized instance
      # variables like `@diff_file` and `@diff_line` from being serialized.
      def init_with(coder)
        initialize(coder['attributes'])

        self
      end

      def encode_with(coder)
        coder['attributes'] = formatter.to_h
      end

      def key
        formatter.key
      end

      def ==(other)
        other.is_a?(self.class) &&
          other.diff_refs == diff_refs &&
          other.old_path == old_path &&
          other.new_path == new_path &&
          other.formatter == formatter
      end

      def to_h
        formatter.to_h
      end

      def inspect
        %(#<#{self.class}:#{object_id} #{to_h}>)
      end

      def complete?
        file_path.present? && formatter.complete? && diff_refs.complete?
      end

      def to_json(opts = nil)
        Gitlab::Json.generate(to_h.except(:ignore_whitespace_change), opts)
      end

      def as_json(opts = nil)
        to_h.except(:ignore_whitespace_change).as_json(opts)
      end

      def type
        formatter.line_age
      end

      def unfoldable?
        on_text? && unchanged?
      end

      def unchanged?
        type.nil?
      end

      def added?
        type == 'new'
      end

      def removed?
        type == 'old'
      end

      def paths
        [old_path, new_path].compact.uniq
      end

      def file_path
        new_path.presence || old_path
      end

      def diff_refs
        @diff_refs ||= DiffRefs.new(base_sha: base_sha, start_sha: start_sha, head_sha: head_sha)
      end

      def unfolded_diff?(repository)
        diff_file(repository)&.unfolded?
      end

      def diff_file(repository)
        return @diff_file if defined?(@diff_file)

        @diff_file = begin
          key = {
            project_id: repository.project.id,
            start_sha: start_sha,
            head_sha: head_sha,
            path: file_path
          }

          # Takes action when creating diff notes (multiple calls are
          # submitted to this method).
          Gitlab::SafeRequestStore.fetch(key) { find_diff_file(repository) }
        end

        # We need to unfold diff lines according to the position in order
        # to correctly calculate the line code and trace position changes.
        @diff_file&.tap { |file| file.unfold_diff_lines(self) }
      end

      def diff_options
        { paths: paths, expanded: true, include_stats: false, ignore_whitespace_change: ignore_whitespace_change }
      end

      def diff_line(repository)
        @diff_line ||= diff_file(repository)&.line_for_position(self)
      end

      def line_code(repository)
        @line_code ||= diff_file(repository)&.line_code_for_position(self)
      end

      def file_hash
        @file_hash ||= Digest::SHA1.hexdigest(file_path)
      end

      def on_file?
        position_type == 'file'
      end

      def on_image?
        position_type == 'image'
      end

      def on_text?
        position_type == 'text'
      end

      def find_diff_file_from(diffable)
        diff_files = diffable.diffs(diff_options).diff_files

        diff_files.first
      end

      def multiline?
        return unless on_text? && line_range

        line_range['start'] != line_range['end']
      end

      private

      def find_diff_file(repository)
        return unless diff_refs.complete?
        return unless comparison = diff_refs.compare_in(repository.project)

        find_diff_file_from(comparison)
      end

      def get_formatter_class(type)
        type ||= "text"

        case type
        when 'image'
          Gitlab::Diff::Formatters::ImageFormatter
        when 'file'
          Gitlab::Diff::Formatters::FileFormatter
        else
          Gitlab::Diff::Formatters::TextFormatter
        end
      end
    end
  end
end
