# frozen_string_literal: true

module Banzai
  module Filter
    # This filter forces the parsing of HTML to DOM to happen in a known place,
    # such that we can profile it on its own.
    #
    # (If we don't do this, it'll happen the first time a filter asks for `doc`.
    # See HTML::Pipeline::Filter#doc.)
    #
    # Errors such as excessive nesting depth are handled at the parsing layer
    # itself; see HTML::Pipeline::HTML5Patch.
    class ParseHtmlFilter < HTML::Pipeline::Filter
      def call
        doc
      end
    end
  end
end
