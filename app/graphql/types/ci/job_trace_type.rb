# frozen_string_literal: true

# rubocop: disable Graphql/AuthorizeTypes
module Types
  module Ci
    class JobTraceType < BaseObject
      graphql_name 'CiJobTrace'
      MAX_SIZE_KB = 16
      MAX_SIZE_B = MAX_SIZE_KB * 1024

      field :html_summary, GraphQL::Types::String, null: false,
        experiment: { milestone: '15.11' },
        description: 'HTML summary that contains the tail lines of the trace. ' \
          "Returns at most #{MAX_SIZE_KB}KB of raw bytes from the trace. " \
          'The returned string might start with an unexpected invalid UTF-8 code point due to truncation.' do
        argument :last_lines, Integer,
          required: false, default_value: 10,
          description: 'Number of tail lines to return, up to a maximum of 100 lines.'
      end

      def html_summary(last_lines:)
        object.html(
          last_lines: last_lines.clamp(1, 100),
          max_size: MAX_SIZE_B
        ).html_safe
      end
    end
  end
end
# rubocop: enable Graphql/AuthorizeTypes
