# frozen_string_literal: true

module Keeps
  module Helpers
    module RubocopFixer
      # Handles file manipulation for Rubocop todos
      # Specifically removing the first `remove_count` exclusions from a given file
      class FileHelper
        def remove_first_exclusions(file, remove_count)
          content = File.read(file)
          skipped = 0

          output = content.each_line.filter do |line|
            if skipped < remove_count && line.match?(/\s+-\s+/)
              skipped += 1
              false
            else
              true
            end
          end

          File.write(file, output.join)
        end
      end
    end
  end
end
