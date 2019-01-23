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
  end
end
