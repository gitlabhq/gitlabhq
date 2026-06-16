# frozen_string_literal: true

module Gitlab
  module PrinciplesDistiller
    class Sync
      # Stateless text helpers for the post-distillation pipeline: strip LLM preamble, suppress rephrasing noise, decide
      # whether a newly distilled file is materially different.
      module Diff
        extend self

        # Strips everything before the first Markdown heading and the trailing empty "## Output Format" sentinel some
        # LLMs leave behind.
        def strip_preamble(content)
          content
            .sub(/\A.*?(?=^#\s)/m, '')
            .sub(/^## Output Format\s*\z/m, '')
            .rstrip.then { |s| "#{s}\n" }
        end

        # Per-section line matching: new lines that closely match an old line (>= MATCH_THRESHOLD word overlap) keep the
        # old wording.
        # Sections only in old are dropped; sections only in new are kept.
        def reduce_noise(old_content, new_content)
          old_sections = parse_sections(old_content)
          new_sections = parse_sections(new_content)

          result_lines = []

          new_sections.each do |heading, new_lines|
            old_lines = old_sections[heading]

            unless old_lines
              result_lines << heading if heading
              result_lines.concat(new_lines)
              next
            end

            result_lines << heading if heading
            old_pool = old_lines.dup

            new_lines.each do |new_line|
              best_match, best_score = find_best_match(new_line, old_pool)

              if best_score >= MATCH_THRESHOLD
                result_lines << best_match
                old_pool.delete_at(old_pool.index(best_match))
              else
                result_lines << new_line
              end
            end
          end

          result_lines.join("\n").then { |s| "#{s}\n" }
        end

        # Ignores whitespace and blank lines. nil updated => false; nil current with non-nil updated => true.
        def meaningful?(current, updated)
          return false if updated.nil?
          return true if current.nil?

          normalize_text(current) != normalize_text(updated)
        end

        private

        # Word-overlap above which a line is considered the "same item
        # reworded"; keep the old wording to suppress diff noise.
        MATCH_THRESHOLD = 0.6

        # Parse into { heading => [lines] } preserving order; preamble before the
        # first heading uses nil as key. Splits on both `## ` (h2) and `### `
        # (h3) so a newly-added top-level section becomes its own section
        # instead of being absorbed into the preceding section's lines (which
        # let reduce_noise drop or mishandle whole new `## ` sections).
        def parse_sections(content)
          sections = {}
          current_heading = nil
          current_lines = []

          content.each_line(chomp: true) do |line|
            if section_heading?(line)
              sections[current_heading] = current_lines
              current_heading = line
              current_lines = []
            else
              current_lines << line
            end
          end

          sections[current_heading] = current_lines
          sections
        end

        def section_heading?(line)
          line.start_with?('## ', '### ')
        end

        # Jaccard similarity over word tokens.
        def word_similarity(line_a, line_b)
          words_a = line_a.downcase.gsub(/[^a-z0-9_\s]/, '').split
          words_b = line_b.downcase.gsub(/[^a-z0-9_\s]/, '').split
          return 0.0 if words_a.empty? && words_b.empty?

          intersection = words_a & words_b
          union = (words_a | words_b)
          union.empty? ? 0.0 : intersection.size.to_f / union.size
        end

        def find_best_match(line, candidates)
          best_match = nil
          best_score = 0.0

          candidates.each do |candidate|
            score = word_similarity(line, candidate)
            next unless score > best_score

            best_score = score
            best_match = candidate
            break if score >= 1.0
          end

          [best_match, best_score]
        end

        def normalize_text(text)
          text.strip.lines.map(&:strip).reject(&:empty?)
        end
      end
    end
  end
end
