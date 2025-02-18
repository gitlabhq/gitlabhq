# frozen_string_literal: true

module Blobs
  class UnfoldPresenter < BlobPresenter
    include ActiveModel::Attributes
    include ActiveModel::AttributeAssignment
    include Gitlab::Utils::StrongMemoize

    presents ::Blob

    attribute :full, :boolean, default: false
    attribute :since, :integer, default: 1
    attribute :to, :integer, default: 1
    attribute :bottom, :boolean, default: false
    attribute :unfold, :boolean, default: true
    attribute :offset, :integer, default: 0
    attribute :indent, :integer, default: 0

    alias_method :full?, :full
    alias_method :bottom?, :bottom
    alias_method :unfold?, :unfold

    def initialize(blob, params)
      super(blob)
      self.attributes = params

      # Load all blob data first as we need to ensure they're all loaded first
      # so we can accurately show the rest of the diff when unfolding.
      load_all_blob_data

      handle_full_or_end!
    end

    # Returns an array of Gitlab::Diff::Line with match line added
    def diff_lines(with_positions_and_indent: false)
      diff_lines = lines.map.with_index do |line, index|
        full_line = limited_blob_lines[index].delete("\n")

        if with_positions_and_indent
          new_pos = index + since
          old_pos = new_pos - offset
          line[0, 0] = ' '
          Gitlab::Diff::Line.new(full_line, nil, nil, old_pos, new_pos, rich_text: line)
        else
          Gitlab::Diff::Line.new(full_line, nil, nil, nil, nil, rich_text: line)
        end
      end

      add_match_line(diff_lines)

      diff_lines
    end

    def lines
      strong_memoize(:lines) do
        limit(highlight(to: to).lines).map(&:html_safe)
      end
    end

    def match_line_text
      return '' if bottom?

      lines_length = lines.length - 1
      line = [since, lines_length].join(',')
      "@@ -#{line}+#{line} @@"
    end

    private

    def handle_full_or_end!
      return unless full? || to == -1

      self.since = 1 if full?

      self.attributes = {
        to: all_lines_size,
        bottom: false,
        unfold: false,
        offset: 0,
        indent: 0
      }
    end

    def all_lines_size
      strong_memoize(:all_lines_size) do
        all_lines.size
      end
    end

    def add_match_line(diff_lines)
      return unless unfold?
      return if bottom? && to >= all_lines_size

      if bottom? && to < all_lines_size
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

    def limited_blob_lines
      strong_memoize(:limited_blob_lines) do
        limit(all_lines)
      end
    end

    def limit(lines)
      return lines if full?

      lines[since - 1..to - 1] || []
    end
  end
end
