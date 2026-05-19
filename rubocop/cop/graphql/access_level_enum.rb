# frozen_string_literal: true

module RuboCop
  module Cop
    module Graphql
      # Checks that GraphQL fields and arguments for access levels
      # use a dedicated enum type instead of `GraphQL::Types::Int`.
      #
      # @example
      #
      #   # bad
      #   argument :access_level, GraphQL::Types::Int
      #
      #   # good
      #   argument :access_level, Types::AccessLevelEnum
      #
      class AccessLevelEnum < RuboCop::Cop::Base
        MSG = 'Do not use `GraphQL::Types::Int` for access level fields. ' \
          'Use a dedicated enum type (e.g., `Types::AccessLevelEnum`) or ' \
          '`Types::AccessLevelType` instead.'

        # @!method graphql_int_field_or_argument?(node)
        def_node_matcher :graphql_int_field_or_argument?, <<~PATTERN
          (send nil? {:field :argument}
            (sym $_)
            {
              (const (const (const {nil? (cbase)} :GraphQL) :Types) :Int)
              (hash <(pair (sym :type) (const (const (const {nil? (cbase)} :GraphQL) :Types) :Int)) ...>)
            }
            ...)
        PATTERN

        def on_send(node)
          graphql_int_field_or_argument?(node) do |name|
            add_offense(node) if access_level_field?(name)
          end
        end
        alias_method :on_csend, :on_send

        private

        def access_level_field?(name)
          name.to_s.include?('access_level')
        end
      end
    end
  end
end
