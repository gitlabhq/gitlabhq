# frozen_string_literal: true

require_relative "../../code_reuse_helpers"

module RuboCop
  module Cop
    module API
      # Checks that API params using Procs in `values:` or `default:` have documentation.
      # Linter can be disabled with documentation: false
      #
      # @example
      #
      #   # bad (has Proc in values without documentation)
      #     params do
      #       requires :status, type: String, values: -> { Status.names }
      #     end
      #
      #   # bad (has Proc in default without documentation)
      #     params do
      #       optional :limit, type: Integer, default: -> { Config.default_limit }
      #     end
      #
      #   # good (has Proc with documentation)
      #     params do
      #       requires :status, type: String, values: -> { Status.names }, documentation: { example: 'active' }
      #       optional :limit, type: Integer, default: -> { Config.default_limit }, documentation: { example: 10 }
      #     end
      #
      #   # good (no Proc, documentation not required)
      #     params do
      #       requires :id, types: [String, Integer], desc: 'The ID of the project'
      #       optional :search, type: String, desc: 'Search string'
      #     end
      #
      #   # good (documentation explicitly disabled)
      #     params do
      #       requires :status, type: String, values: -> { Status.names }, documentation: false
      #     end
      #
      #   # bad (Proc assigned to variable and used in values)
      #     values = proc { Status.names }
      #     params do
      #       requires :status, type: String, values: values
      #     end
      #
      class ParameterDocumentation < RuboCop::Cop::Base
        include CodeReuseHelpers

        MESSAGES = {
          values: "Parameter is constrained to a set of values determined at runtime. " \
            "Include a `documentation` field to inform about the allowed values as precisely as possible.",
          default: "Parameter has a default value determined at runtime. " \
            "Include a `documentation` field to inform about the default as precisely as possible."
        }.freeze
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

        # @!method has_documentation?(node)
        def_node_matcher :has_documentation?, <<~PATTERN
          (send _
            ...
            (hash <(pair (sym :documentation) _) ...>)
          )
        PATTERN

        # @!method proc_used?(node)
        def_node_matcher :proc_used?, <<~PATTERN
          (send _
            ...
            (hash <(pair (sym ${:values :default}) #{PROC_PATTERN}) ...>)
          )
        PATTERN

        # @!method variable_used?(node)
        def_node_matcher :variable_used?, <<~PATTERN
          (send _
            ...
            (hash <(pair (sym ${:values :default}) (lvar $_name)) ...>)
          )
        PATTERN

        def on_send(node)
          return if has_documentation?(node)

          key = proc_used?(node) || proc_variable_used?(node)
          add_offense(node, message: MESSAGES[key]) if key
        end
        alias_method :on_csend, :on_send

        private

        def proc_variable_used?(node)
          variable_used?(node) { |key, name| key if @proc_variables[name] }
        end
      end
    end
  end
end
