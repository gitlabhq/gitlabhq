# frozen_string_literal: true

module Banzai
  module Filter
    class TruncateSourceFilter < HTML::Pipeline::TextFilter
      def call
        return text unless context.key?(:limit)

        text.truncate_bytes(context[:limit])
      end
    end
  end
end
