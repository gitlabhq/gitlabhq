# frozen_string_literal: true

module RuboCop
  module Cop
    module API
      class GrapeArrayMissingCoerce < RuboCop::Cop::Base
        # This cop checks that Grape API parameters using an Array type
        # implement a coerce_with method:
        #
        # https://github.com/ruby-grape/grape/blob/master/UPGRADING.md#ensure-that-array-types-have-explicit-coercions
        #
        # @example
        #
        # # bad
        # requires :values, type: Array[String]
        #
        # # good
        # requires :values, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce
        #
        # end
        MSG = 'This Grape parameter defines an Array but is missing a coerce_with definition. ' \
          'For more details, see https://github.com/ruby-grape/grape/blob/master/UPGRADING.md#ensure-that-array-types-have-explicit-coercions'

        def_node_matcher :grape_api_instance?, <<~PATTERN
          (class
            (const _ _)
            (const
              (const
                (const nil? :Grape) :API) :Instance)
            ...
          )
        PATTERN

        def_node_matcher :grape_api_param_block?, <<~PATTERN
          (send _ {:requires :optional}
            (sym _)
            $_)
        PATTERN

        def_node_matcher :grape_type_def?, <<~PATTERN
           (sym :type)
        PATTERN

        def_node_matcher :grape_array_type?, <<~PATTERN
           (send
             (const nil? :Array) :[]
             (const nil? _))
        PATTERN

        def_node_matcher :grape_coerce_with?, <<~PATTERN
          (sym :coerce_with)
        PATTERN

        def on_class(node)
          @grape_api ||= grape_api_instance?(node)
        end

        def on_send(node)
          return unless @grape_api

          match = grape_api_param_block?(node)

          return unless match.is_a?(RuboCop::AST::HashNode)

          is_array_type = false
          has_coerce_method = false

          match.each_pair do |first, second|
            has_coerce_method ||= grape_coerce_with?(first)

            if grape_type_def?(first) && grape_array_type?(second)
              is_array_type = true
            end
          end

          if is_array_type && !has_coerce_method
            add_offense(node)
          end
        end
      end
    end
  end
end
