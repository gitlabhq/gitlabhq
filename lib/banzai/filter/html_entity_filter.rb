require 'erb'

module Banzai
  module Filter
    # Text filter that escapes these HTML entities: & " < >
    class HtmlEntityFilter < HTML::Pipeline::TextFilter
      def call
        ERB::Util.html_escape(text)
      end
    end
  end
end
