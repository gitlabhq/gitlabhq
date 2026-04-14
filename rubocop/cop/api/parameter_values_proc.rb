# frozen_string_literal: true

# rubocop:disable Lint/RedundantCopDisableDirective -- used in example

require_relative "../../code_reuse_helpers"

module RuboCop
  module Cop
    module API
      # Procs should not be used to set values option for params
      # Checks that API params using `values:` option do not implement Procs
      #
      # @example
      #
      #   # bad - proc wrapping a static value
      #   params do
      #     requires :status, type: String, values: -> { Status::STATUS_NAMES }
      #   end
      #
      #   # good - reference the constant directly
      #   params do
      #     requires :status, type: String, values: Status::STATUS_NAMES
      #   end
      #
      #   # bad - validator proc
      #   params do
      #     requires :status, type: String, values: { value: ->(v) { v.length <= Status::MAX_LENGTH } }
      #   end
      #
      #   # good - use a custom validator or `limit:` instead
      #   params do
      #     requires :status, type: String, limit: Status::MAX_LENGTH
      #   end
      #
      #   # bad - proc assigned to a variable
      #   status_values = proc { Status.all_names }
      #   params do
      #     requires :status, type: String, values: status_values
      #   end
      #
      #   # good - use a static array instead
      #   params do
      #     requires :status, type: String, values: %w[active inactive]
      #   end
      #
      #   # bad - validator proc wraps a static range
      #   params do
      #     requires :status, type: Integer, values: ->(v) { v >= 1 && v <= 100 }
      #   end
      #
      #   # good - use the range directly
      #   params do
      #     requires :status, type: Integer, values: 1..100
      #   end
      #
      class ParameterValuesProc < RuboCop::Cop::Base
        include CodeReuseHelpers

        MESSAGE = "Do not use a Proc for `values:` in API parameters. " \
          "Proc-based values cannot be represented as a static enum in the OpenAPI spec. " \
          "Use a statically resolvable value instead (e.g. an array, range, or constant). "

        RESTRICT_ON_SEND = %i[requires optional].freeze

        PROC_PATTERN = "{(block (send nil? :proc) ...) (block (send nil? :lambda) ...) " \
          "(block (send (const nil? :Proc) :new) ...) (send nil? :proc) (send nil? :lambda) " \
          "(send _ :to_proc)}"

        def on_new_investigation
          @proc_variables = {}
        end

        # @!method proc_assignment?(node)
        def_node_matcher :proc_assignment?, <<~PATTERN
          (lvasgn $_name #{PROC_PATTERN})
        PATTERN

        def on_lvasgn(node)
          proc_assignment?(node) do |name|
            @proc_variables[name] = true
          end
        end

        # @!method values_proc?(node)
        def_node_matcher :values_proc?, <<~PATTERN
          (send _
            ...
            (hash <(pair (sym :values) #{PROC_PATTERN}) ...>)
          )
        PATTERN

        # @!method values_hash_proc?(node)
        def_node_matcher :values_hash_proc?, <<~PATTERN
          (send _
            ...
            (hash <(pair (sym :values) (hash <(pair _ #{PROC_PATTERN}) ...>)) ...>)
          )
        PATTERN

        # @!method values_variable?(node)
        def_node_matcher :values_variable?, <<~PATTERN
          (send _
            ...
            (hash <(pair (sym :values) (lvar $_name)) ...>)
          )
        PATTERN

        def on_send(node)
          return unless values_proc?(node) ||
            values_hash_proc?(node) ||
            values_variable?(node) { |name| @proc_variables[name] }

          add_offense(node, message: MESSAGE)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
# rubocop:enable Lint/RedundantCopDisableDirective
