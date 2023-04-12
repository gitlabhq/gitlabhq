# frozen_string_literal: true

# rubocop: disable Graphql/AuthorizeTypes
module Types
  module Ci
    class JobTraceType < BaseObject
      graphql_name 'CiJobTrace'

      field :html_summary, GraphQL::Types::String, null: false,
        alpha: { milestone: '15.11' }, # As we want the option to change from 10 if needed
        description: "HTML summary containing the last 10 lines of the trace."

      def html_summary
        object.html(last_lines: 10).html_safe
      end
    end
  end
end
# rubocop: enable Graphql/AuthorizeTypes
