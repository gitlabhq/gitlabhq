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
               :position_type, to: :formatter

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
        JSON.generate(formatter.to_h, opts)
      end

      def type
        formatter.line_age
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

      def diff_file(repository)
        return @diff_file if defined?(@diff_file)

        @diff_file = begin
          if RequestStore.active?
            key = {
              project_id: repository.project.id,
              start_sha: start_sha,
              head_sha: head_sha,
              path: file_path
            }

            RequestStore.fetch(key) { find_diff_file(repository) }
          else
            find_diff_file(repository)
          end
        end
      end

      def diff_line(repository)
        @diff_line ||= diff_file(repository)&.line_for_position(self)
      end

      def line_code(repository)
        @line_code ||= diff_file(repository)&.line_code_for_position(self)
      end

      private

      def find_diff_file(repository)
        return unless diff_refs.complete?
        return unless comparison = diff_refs.compare_in(repository.project)

        comparison.diffs(paths: paths, expanded: true).diff_files.first
      end

      def get_formatter_class(type)
        type ||= "text"

        case type
        when 'image'
          Gitlab::Diff::Formatters::ImageFormatter
        else
          Gitlab::Diff::Formatters::TextFormatter
        end
      end
    end
  end
end
