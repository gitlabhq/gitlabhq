# frozen_string_literal: true

module Gitlab
  module Diff
    class Line
      # When SERIALIZE_KEYS is updated, to reset the redis cache entries you'll
      #   need to bump the VERSION constant on Gitlab::Diff::HighlightCache
      #
      SERIALIZE_KEYS = %i(line_code rich_text text type index old_pos new_pos).freeze

      attr_reader :line_code, :type, :old_pos, :new_pos
      attr_writer :rich_text
      attr_accessor :text, :index

      def initialize(text, type, index, old_pos, new_pos, parent_file: nil, line_code: nil, rich_text: nil)
        @text, @type, @index = text, type, index
        @old_pos, @new_pos = old_pos, new_pos
        @parent_file = parent_file
        @rich_text = rich_text

        # When line code is not provided from cache store we build it
        # using the parent_file(Diff::File or Conflict::File).
        @line_code = line_code || calculate_line_code
      end

      def self.init_from_hash(hash)
        new(hash[:text],
            hash[:type],
            hash[:index],
            hash[:old_pos],
            hash[:new_pos],
            parent_file: hash[:parent_file],
            line_code: hash[:line_code],
            rich_text: hash[:rich_text])
      end

      def self.safe_init_from_hash(hash)
        line = hash.with_indifferent_access
        rich_text = line[:rich_text]
        line[:rich_text] = rich_text&.html_safe

        init_from_hash(line)
      end

      def to_hash
        hash = {}
        SERIALIZE_KEYS.each { |key| hash[key] = send(key) } # rubocop:disable GitlabSecurity/PublicSend
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

      def match?
        type == :match
      end

      def discussable?
        !meta?
      end

      def suggestible?
        !removed?
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

      # We have to keep this here since it is still used for conflict resolution
      # Conflict::File#as_json renders json diff lines in sections
      def as_json(opts = nil)
        DiffLineSerializer.new.represent(self)
      end

      private

      def calculate_line_code
        @parent_file&.line_code(self)
      end
    end
  end
end
