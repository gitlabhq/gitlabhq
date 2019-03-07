# frozen_string_literal: true

require 'gt_one_coercion'

module Blobs
  class UnfoldPresenter < BlobPresenter
    include Virtus.model
    include Gitlab::Utils::StrongMemoize

    attribute :full, Boolean, default: false
    attribute :since, GtOneCoercion
    attribute :to, GtOneCoercion
    attribute :bottom, Boolean
    attribute :unfold, Boolean, default: true
    attribute :offset, Integer
    attribute :indent, Integer, default: 0

    def initialize(blob, params)
      @subject = blob
      @all_lines = highlight.lines
      super(params)

      if full?
        self.attributes = { since: 1, to: @all_lines.size, bottom: false, unfold: false, offset: 0, indent: 0 }
      end
    end

    # Converts a String array to Gitlab::Diff::Line array, with match line added
    def diff_lines
      diff_lines = lines.map do |line|
        Gitlab::Diff::Line.new(line, nil, nil, nil, nil, rich_text: line)
      end

      add_match_line(diff_lines)

      diff_lines
    end

    def lines
      strong_memoize(:lines) do
        lines = @all_lines
        lines = lines[since - 1..to - 1] unless full?
        lines.map(&:html_safe)
      end
    end

    def match_line_text
      return '' if bottom?

      lines_length = lines.length - 1
      line = [since, lines_length].join(',')
      "@@ -#{line}+#{line} @@"
    end

    private

    def add_match_line(diff_lines)
      return unless unfold?

      if bottom? && to < @all_lines.size
        old_pos = to - offset
        new_pos = to
      elsif since != 1
        old_pos = new_pos = since
      end

      # Match line is not needed when it reaches the top limit or bottom limit of the file.
      return unless new_pos

      match_line = Gitlab::Diff::Line.new(match_line_text, 'match', nil, old_pos, new_pos)

      bottom? ? diff_lines.push(match_line) : diff_lines.unshift(match_line)
    end
  end
end
