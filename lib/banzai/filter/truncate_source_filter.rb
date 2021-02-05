# frozen_string_literal: true

module Banzai
  module Filter
    class TruncateSourceFilter < HTML::Pipeline::TextFilter
      def call
        return text unless context.key?(:limit)

        # Use three dots instead of the ellipsis Unicode character because
        # some clients show the raw Unicode value in the merge commit.
        text.truncate_bytes(context[:limit], omission: '...')
      end
    end
  end
end
