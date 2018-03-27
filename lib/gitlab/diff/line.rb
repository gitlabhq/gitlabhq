module Gitlab
  module Diff
    class Line
      attr_reader :type, :index, :old_pos, :new_pos
      attr_writer :rich_text
      attr_accessor :text

      def initialize(text, type, index, old_pos, new_pos, parent_file: nil)
        @text, @type, @index = text, type, index
        @old_pos, @new_pos = old_pos, new_pos
        @parent_file = parent_file
      end

      def self.init_from_hash(hash)
        new(hash[:text], hash[:type], hash[:index], hash[:old_pos], hash[:new_pos])
      end

      def serialize_keys
        @serialize_keys ||= %i(text type index old_pos new_pos)
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
        @parent_file.highlight_lines! if @parent_file && !@rich_text

        @rich_text
      end

      def as_json(opts = nil)
        {
          type: type,
          old_line: old_line,
          new_line: new_line,
          text: text,
          rich_text: rich_text || text
        }
      end
    end
  end
end
