# frozen_string_literal: true

module Banzai
  module Filter
    module Concerns
      module TextReplacer
        extend ActiveSupport::Concern

        # REFERENCE_PLACEHOLDER is used for replacement HTML to be inserted during
        # reference matching.  The random string helps ensure it's pretty close to unique.
        # Since it's a transitory value (it's never persisted anywhere) we can initialize once,
        # and it doesn't matter if it changes on a restart.
        REFERENCE_PLACEHOLDER = "_reference_#{SecureRandom.hex(16)}_".freeze
        REFERENCE_PLACEHOLDER_PATTERN = %r{#{REFERENCE_PLACEHOLDER}(\d+)}

        # A helper to make it easier to substitute HTML into matched text correctly.
        #
        # Pass in the replacement Enumerator of choice, on *plain text* input.
        # This will often look like this:
        #
        #   Gitlab::Utils::Gsub.gsub_with_limit(text, pattern, limit: Banzai::Filter::FILTER_ITEM_LIMIT)
        #
        # Or the simpler:
        #
        #   text.gsub(pattern)
        #
        # In both cases, the subject we're performing replacements on is text, not HTML.
        #
        # This function will yield MatchData from the underlying enumerator -- $~ if it's available,
        # otherwise the yield from the enumerator itself is asserted to be MatchData or RE2::MatchData.
        # The given block should return HTML (!) to substitute in place, or nil if no replacement
        # is to be made.
        #
        # The function returns HTML, safely substituting the block results in, while escaping all
        # other text.  The supplied block MUST escape any input text returned within it, if any.
        #
        # If no replacements were made --- that is, the enumerator didn't yield anything, or the block
        # given to this function only returned nil --- nil is returned.
        def replace_references_in_text_with_html(enumerator)
          replacements = {}

          # We operate on text, yield text, and substitute back in only text.
          replaced_text = enumerator.with_index do |enumerator_yielded, index|
            match_data = $~ || enumerator_yielded
            unless match_data.is_a?(MatchData) || match_data.is_a?(RE2::MatchData)
              raise ArgumentError, "enumerator didn't yield MatchData (is #{match_data.inspect}) and $~ is unavailable"
            end

            replacement = yield match_data
            if replacement
              # The yield returns HTML to us, but we can't substitute it back in yet --- there
              # remains unescaped, textual content in unmatched parts of the string which we
              # need to escape without affecting the block yields.  Instead, store the result,
              # and substitute back into the text a placeholder we can replace after escaping.
              replacements[index] = replacement
              "#{REFERENCE_PLACEHOLDER}#{index}"
            else
              match_data.to_s
            end
          end

          return unless replacements.any?

          # Escape the replaced_text --- which doesn't change the placeholders --- and only then
          # replace the placeholders with the yielded HTML.
          CGI.escapeHTML(replaced_text).gsub(REFERENCE_PLACEHOLDER_PATTERN) do
            replacements[Regexp.last_match(1).to_i]
          end
        end
      end
    end
  end
end
