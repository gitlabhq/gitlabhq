# frozen_string_literal: true

# This class replaces Github markdown suggestion tag with
# a Gitlab suggestion tag. The difference between
# Github's and Gitlab's suggestion tags is that Gitlab
# includes the range of the suggestion in the tag, while Github
# uses other note attributes to position the suggestion.
module Gitlab
  module GithubImport
    module Representation
      module DiffNotes
        class SuggestionFormatter
          include Gitlab::Utils::StrongMemoize

          # A github suggestion:
          # - the ```suggestion tag must be the first text of the line
          #   - it might have up to 3 spaces before the ```suggestion tag
          # - extra text on the ```suggestion tag line will be ignored
          GITHUB_SUGGESTION = /^\ {,3}(?<suggestion>```suggestion\b).*(?<eol>\R)/

          def initialize(note:, start_line: nil, end_line: nil)
            @note = note
            @start_line = start_line
            @end_line = end_line
          end

          # Returns a tuple with:
          #   - a boolean indicating if the note has suggestions
          #   - the note with the suggestion formatted for Gitlab
          def formatted_note
            @formatted_note ||=
              if contains_suggestion?
                note.gsub(
                  GITHUB_SUGGESTION,
                  "\\k<suggestion>:#{suggestion_range}\\k<eol>"
                )
              else
                note
              end
          end

          def contains_suggestion?
            strong_memoize(:contain_suggestion) do
              note.to_s.match?(GITHUB_SUGGESTION)
            end
          end

          private

          attr_reader :note, :start_line, :end_line

          # Github always saves the comment on the _last_ line of the range.
          # Therefore, the diff hunk will always be related to lines before
          # the comment itself.
          def suggestion_range
            "-#{line_count}+0"
          end

          def line_count
            if start_line.present?
              end_line - start_line
            else
              0
            end
          end
        end
      end
    end
  end
end
