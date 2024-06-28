# frozen_string_literal: true

module Banzai
  module Filter
    module Concerns
      module OutputSafety
        def escape_once(html)
          html.html_safe? ? html : ERB::Util.html_escape_once(html)
        end
      end
    end
  end
end
