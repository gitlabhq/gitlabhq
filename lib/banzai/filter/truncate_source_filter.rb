# frozen_string_literal: true

module Banzai
  module Filter
    class TruncateSourceFilter < HTML::Pipeline::TextFilter
      CHARACTER_COUNT_LIMIT = 1.megabyte
      USER_MSG_LIMIT = 10_000

      def call
        # don't truncate if it's a :blob and no limit is set
        return text if context[:text_source] == :blob && !context.key?(:limit)

        limit = context[:limit] || CHARACTER_COUNT_LIMIT

        # no sense in allowing `truncate_bytes` to duplicate a large
        # string unless it's too big
        return text if text.bytesize <= limit

        # Use three dots instead of the ellipsis Unicode character because
        # some clients show the raw Unicode value in the merge commit.
        trunc = text.truncate_bytes(limit, omission: '...')

        # allows us to indicate to the user that what they see is a truncated copy
        if limit > USER_MSG_LIMIT
          trunc.prepend("_The text is longer than #{limit} characters and has been visually truncated._\n\n")
        end

        trunc
      end
    end
  end
end
