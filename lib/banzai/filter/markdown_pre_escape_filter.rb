# frozen_string_literal: true

module Banzai
  module Filter
    # In order to allow a user to short-circuit our reference shortcuts
    # (such as # or !), the user should be able to escape them, like \#.
    # CommonMark supports this, however it removes all information about
    # what was actually a literal.  In order to short-circuit the reference,
    # we must surround backslash escaped ASCII punctuation with a custom sequence.
    # This way CommonMark will properly handle the backslash escaped chars
    # but we will maintain knowledge (the sequence) that it was a literal.
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
    # This filter does the initial surrounding, and MarkdownPostEscapeFilter
    # does the conversion into span tags.
    class MarkdownPreEscapeFilter < HTML::Pipeline::TextFilter
      # We just need to target those that are special GitLab references
      REFERENCE_CHARACTERS = '@#!$&~%^'
      ASCII_PUNCTUATION    = %r{(\\[#{REFERENCE_CHARACTERS}])}.freeze
      LITERAL_KEYWORD      = 'cmliteral'

      def call
        @text.gsub(ASCII_PUNCTUATION) do |match|
          # The majority of markdown does not have literals.  If none
          # are found, we can bypass the post filter
          result[:escaped_literals] = true

          "#{LITERAL_KEYWORD}-#{match}-#{LITERAL_KEYWORD}"
        end
      end
    end
  end
end
