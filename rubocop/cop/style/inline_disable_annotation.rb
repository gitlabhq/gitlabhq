# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # rubocop:disable Lint/RedundantCopDisableDirective -- For examples
      # Checks that rubocop inline disabling is formatted according
      # to guidelines.
      # See: https://docs.gitlab.com/ee/development/rubocop_development_guide.html#disabling-rules-inline,
      # https://gitlab.com/gitlab-org/gitlab/-/issues/428762
      #
      #   # bad
      #   # rubocop:disable Some/Cop, Another/Cop
      #
      #   # good
      #   # rubocop:disable Some/Cop, Another/Cop -- Some reason
      #
      # rubocop:enable Lint/RedundantCopDisableDirective
      class InlineDisableAnnotation < RuboCop::Cop::Base
        include RangeHelp

        COP_DISABLE = '#\s*rubocop\s*:\s*(?:disable|todo)\s+'
        BAD_DISABLE = %r{\A(?<line>(?<disabling>#{COP_DISABLE}(?:[\w/]+(?:\s*,\s*[\w/]+)*))\s*)(?!.*\s*--\s\S).*}
        COP_DISABLE_LINE = /\A(?<line>#{COP_DISABLE}.*)\Z/
        MSG = <<~MESSAGE
          Inline disabling a cop needs to follow the format of `%{disable} -- Some reason`.
          See https://docs.gitlab.com/ee/development/rubocop_development_guide.html#disabling-rules-inline.
        MESSAGE

        def on_new_investigation
          processed_source.comments.each do |comment|
            candidate_match = COP_DISABLE_LINE.match(comment.text)
            # Pre-filter to ensure we are on a comment that is for a rubocop disabling
            next unless candidate_match

            bad_match = BAD_DISABLE.match(comment.text)
            # Only the badly formatted lines make it past this.
            next unless bad_match

            add_offense(
              source_range(
                processed_source.buffer, comment.loc.line, comment.loc.column, candidate_match[:line].length
              ),
              message: format(MSG, disable: bad_match[:disabling])
            )
          end
        end
      end
    end
  end
end
