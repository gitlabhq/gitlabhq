module Gitlab
  module Diff
    class Line
      attr_reader :line_code, :type, :index, :old_pos, :new_pos
      attr_writer :rich_text
      attr_accessor :text

      def initialize(text, type, index, old_pos, new_pos, parent_file: nil, line_code: nil)
        @text, @type, @index = text, type, index
        @old_pos, @new_pos = old_pos, new_pos
        @parent_file = parent_file

        # When line code is not provided from cache store we build it
        # using the parent_file(Diff::File or Conflict::File).
        @line_code = line_code || calculate_line_code
      end

      def self.init_from_hash(hash)
        new(hash[:text], hash[:type], hash[:index], hash[:old_pos], hash[:new_pos], line_code: hash[:line_code])
      end

      def serialize_keys
        @serialize_keys ||= %i(line_code text type index old_pos new_pos)
      end

      def to_hash
        hash = {}
        serialize_keys.each { |key| hash[key] = send(key) } # rubocop:disable GitlabSecurity/PublicSend
        hash
      end

      def old_line
        old_pos unless added? || meta?
      end

      def new_line
        new_pos unless removed? || meta?
      end

      def line
        new_line || old_line
      end

      def unchanged?
        type.nil?
      end

      def added?
        %w[new new-nonewline].include?(type)
      end

      def removed?
        %w[old old-nonewline].include?(type)
      end

      def meta?
        %w[match new-nonewline old-nonewline].include?(type)
      end

      def discussable?
        !meta?
      end

      def rich_text
        @parent_file.try(:highlight_lines!) if @parent_file && !@rich_text

        @rich_text
      end

      def meta_positions
        return unless meta?

        {
          old_pos: old_pos,
          new_pos: new_pos
        }
      end

      def as_json(opts = nil)
        {
          line_code: line_code,
          type: type,
          old_line: old_line,
          new_line: new_line,
          text: text,
          rich_text: rich_text || text,
          meta_data: meta_positions
        }
      end

      private

      def calculate_line_code
        @parent_file&.line_code(self)
      end
    end
  end
end
