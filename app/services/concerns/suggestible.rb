# frozen_string_literal: true

module Suggestible
  extend ActiveSupport::Concern

  # This translates into limiting suggestion changes to `suggestion:-100+100`.
  MAX_LINES_CONTEXT = 100.freeze

  def fetch_from_content
    diff_file.new_blob_lines_between(from_line, to_line).join
  end

  def from_line
    real_above = [lines_above, MAX_LINES_CONTEXT].min
    [target_line - real_above, 1].max
  end

  def to_line
    real_below = [lines_below, MAX_LINES_CONTEXT].min
    target_line + real_below
  end

  def diff_file
    raise NotImplementedError
  end

  def target_line
    raise NotImplementedError
  end
end
