# frozen_string_literal: true

module Banzai
  module Filter
    # TODO: This is now a legacy filter, and is only used with the Ruby parser.
    # The current markdown parser now properly handles escaping characters.
    # The Ruby parser is now only for benchmarking purposes.
    # issue: https://gitlab.com/gitlab-org/gitlab/-/issues/454601
    #
    # In order to allow a user to short-circuit our reference shortcuts
    # (such as # or !), the user should be able to escape them, like \#.
    # CommonMark supports this, however it removes all information about
    # what was actually a literal.  In order to short-circuit the reference,
    # we must surround backslash escaped ASCII punctuation with a custom sequence.
    # This way CommonMark will properly handle the backslash escaped chars
    # but we will maintain knowledge (the sequence) that it was a literal.
    #
    # This processing is also important for the handling of escaped characters
    # in LaTeX math. These will need to be converted back into their escaped
    # versions if they are detected in math blocks.
    #
    # We need to surround the character, not just prefix it.  It could
    # get converted into an entity by CommonMark and we wouldn't know how many
    # characters there are.  The entire literal needs to be surrounded with
    # a `span` tag, which short-circuits our reference processing.
    #
    # We can't use a custom HTML tag since we could be initially surrounding
    # text in an href, and then CommonMark will not be able to parse links
    # properly.  So we use `cmliteral-` and `-cmliteral`
    #
    # https://spec.commonmark.org/0.29/#backslash-escapes
    #
    # This filter does the initial surrounding, and MarkdownPostEscapeLegacyFilter
    # does the conversion into span tags.
    class MarkdownPreEscapeLegacyFilter < HTML::Pipeline::TextFilter
      # Table of characters that need this special handling. It consists of the
      # GitLab special reference characters and special LaTeX characters.
      #
      # The `token` is used when we do the initial replacement - for example converting
      # `\$` into `cmliteral-\+a-cmliteral`. We don't simply replace `\$` with `$`,
      # because this can cause difficulties in parsing math blocks that use `$` as a
      # delimiter.  We also include a character that _can_ be escaped, `\+`.  By examining
      # the text once it's been passed to markdown, we can determine that `cmliteral-\+a-cmliteral`
      # was in a block that markdown did _not_ escape the character, for example an inline
      # code block or some other element.  In this case, we must convert back to the
      # original escaped version, `\$`.  However if we detect `cmliteral-+a-cmliteral`,
      # then we know markdown considered it an escaped character, and we should replace it
      # with the non-escaped version, `$`.
      # See the MarkdownPostEscapeLegacyFilter for how this is done.
      ESCAPABLE_CHARS = [
        { char: '$', escaped: '\$', token: '\+a', reference: true, latex: true },
        { char: '%', escaped: '\%', token: '\+b', reference: true, latex: true },
        { char: '#', escaped: '\#', token: '\+c', reference: true, latex: true },
        { char: '&', escaped: '\&', token: '\+d', reference: true, latex: true },
        { char: '{', escaped: '\{', token: '\+e', reference: false, latex: true },
        { char: '}', escaped: '\}', token: '\+f', reference: false, latex: true },
        { char: '_', escaped: '\_', token: '\+g', reference: false, latex: true },
        { char: '@', escaped: '\@', token: '\+h', reference: true, latex: false },
        { char: '!', escaped: '\!', token: '\+i', reference: true, latex: false },
        { char: '~', escaped: '\~', token: '\+j', reference: true, latex: false },
        { char: '^', escaped: '\^', token: '\+k', reference: true, latex: false }
      ].freeze

      TARGET_CHARS         = ESCAPABLE_CHARS.pluck(:char).join.freeze
      ASCII_PUNCTUATION    = %r{(\\[#{TARGET_CHARS}])}
      LITERAL_KEYWORD      = 'cmliteral'

      def call
        return @text if MarkdownFilter.glfm_markdown?(context)

        @text.gsub(ASCII_PUNCTUATION) do |match|
          # The majority of markdown does not have literals.  If none
          # are found, we can bypass the post filter
          result[:escaped_literals] = true

          escaped_item = ESCAPABLE_CHARS.find { |item| item[:escaped] == match }
          token = escaped_item ? escaped_item[:token] : match

          "#{LITERAL_KEYWORD}-#{token}-#{LITERAL_KEYWORD}"
        end
      end
    end
  end
end
