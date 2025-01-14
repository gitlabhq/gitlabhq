# frozen_string_literal: true

module Gitlab
  module Diff
    class Line
      # When SERIALIZE_KEYS is updated, to reset the redis cache entries you'll
      #   need to bump the VERSION constant on Gitlab::Diff::HighlightCache
      #
      SERIALIZE_KEYS = %i[line_code rich_text text type index old_pos new_pos].freeze

      attr_reader :marker_ranges
      attr_writer :text, :rich_text
      attr_accessor :index, :old_pos, :new_pos, :line_code, :type, :embedded_image

      def initialize(text, type, index, old_pos, new_pos, parent_file: nil, line_code: nil, rich_text: nil)
        @text = text
        @type = type
        @index = index
        @old_pos = old_pos
        @new_pos = new_pos
        @parent_file = parent_file
        @rich_text = rich_text

        # When line code is not provided from cache store we build it
        # using the parent_file(Diff::File or Conflict::File).
        @line_code = line_code || calculate_line_code
        @marker_ranges = []
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

      def set_marker_ranges(marker_ranges)
        @marker_ranges = marker_ranges
      end

      def text(prefix: true)
        return @text if prefix

        @text&.slice(1..).to_s
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
        %w[new new-nonewline new-nomappinginraw].include?(type)
      end

      def removed?
        %w[old old-nonewline old-nomappinginraw].include?(type)
      end

      def meta?
        %w[match new-nonewline old-nonewline].include?(type)
      end

      def has_mapping_in_raw?
        # Used for rendered diff, when the displayed line doesn't have a matching line in the raw diff
        !type&.ends_with?('nomappinginraw')
      end

      def match?
        if Feature.enabled?(:diff_line_match, Feature.current_request)
          type.to_s == 'match'
        else
          type == :match
        end
      end

      def discussable?
        has_mapping_in_raw? && !meta?
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

      def text_content
        rich_text ? rich_text[1..] : text(prefix: false)
      end

      def id(file_hash, side)
        return if meta?

        prefix = side == :old ? "L" : "R"
        position = side == :old ? old_pos : new_pos
        "line_#{file_hash}_#{prefix}#{position}"
      end

      def legacy_id(file_path)
        return if meta?

        Gitlab::Git.diff_line_code(file_path, new_pos, old_pos)
      end

      private

      def calculate_line_code
        @parent_file&.line_code(self)
      end
    end
  end
end
