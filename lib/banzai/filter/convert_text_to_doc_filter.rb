# frozen_string_literal: true

module Banzai
  module Filter
    # This simply forces the conversion of text (which is usually
    # just converted HTML) into a nokogiri document.
    # Forcing this to be done here allows us to understand the performance of this
    # step. Otherwise it is done in the next filter anyway.
    class ConvertTextToDocFilter < HTML::Pipeline::Filter
      def call
        doc
      end
    end
  end
end
