# frozen_string_literal: true

# rubocop: disable Graphql/AuthorizeTypes
module Types
  module Ci
    class JobTraceType < BaseObject
      graphql_name 'CiJobTrace'

      field :html_summary, GraphQL::Types::String, null: false,
        alpha: { milestone: '15.11' },
        description: 'HTML summary that contains the tail lines of the trace.' do
        argument :last_lines, Integer,
          required: false, default_value: 10,
          description: 'Number of tail lines to return, up to a maximum of 100 lines.'
      end

      def html_summary(last_lines:)
        object.html(last_lines: last_lines.clamp(1, 100)).html_safe
      end
    end
  end
end
# rubocop: enable Graphql/AuthorizeTypes
