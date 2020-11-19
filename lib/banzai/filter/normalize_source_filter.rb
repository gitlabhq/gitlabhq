# frozen_string_literal: true

module Banzai
  module Filter
    class NormalizeSourceFilter < HTML::Pipeline::Filter
      UTF8_BOM = "\xEF\xBB\xBF"

      def call
        # Remove UTF8_BOM from beginning of source text
        html.delete_prefix(UTF8_BOM)
      end
    end
  end
end
