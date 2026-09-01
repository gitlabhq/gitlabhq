# frozen_string_literal: true

module Blobs
  class EmailEmbeddedBlobComponent < EmbeddedBlobComponent
    private

    def numbered_lines
      highlighted_lines.each_with_index.map { |line, index| [from + index, line] }
    end
  end
end
