# frozen_string_literal: true

module RuboCop
  module Cop
    module Database
      # Enforces size limits on new JSONB column validations
      #
      # This cop ensures that new json_schema validations include explicit
      # size limits to prevent unbounded JSONB growth that can impact database
      # performance at scale.
      #
      # @example
      #   # bad - no size limit specified
      #   validates :metadata, json_schema: { filename: "project_metadata" }
      #
      #   # good - explicit size limit
      #   validates :metadata, json_schema: { filename: "project_metadata", size_limit: 64.kilobytes }
      #
      class JsonbSizeLimit < RuboCop::Cop::Base
        MSG = 'Add `size_limit` to prevent unbounded jsonb growth. ' \
          'We recommend a maximum of `64.kilobytes`, otherwise use object storage instead. ' \
          'See https://docs.gitlab.com/development/migration_style_guide/#storing-json-in-database'

        RESTRICT_ON_SEND = [:validates].freeze

        # @!method json_schema_validation?(node)
        def_node_matcher :json_schema_validation?, <<~PATTERN
          (send nil? :validates
            (sym _)
            (hash
              <(pair (sym :json_schema) (hash $...)) ...>
            )
          )
        PATTERN

        # @!method has_size_limit?(node)
        def_node_matcher :has_size_limit?, <<~PATTERN
          (pair (sym :size_limit) !nil)
        PATTERN

        def on_send(node)
          json_schema_validation?(node) do |json_schema_pairs|
            next if json_schema_pairs.any? { |pair| has_size_limit?(pair) }

            add_offense(node.loc.selector)
          end
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
