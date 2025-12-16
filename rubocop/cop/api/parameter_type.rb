# frozen_string_literal: true

require_relative '../../code_reuse_helpers'
require_relative '../../node_pattern_helper'
require_relative '../../api_hidden_param_helpers'

module RuboCop
  module Cop
    module API
      # Checks that in API definitions each param type is valid
      # Hidden params are an exception. For example:
      # requires :invisible, type: String, documentation: { hidden: true }
      #
      # @example
      #
      #   # bad
      #     params do
      #       requires :id, types: ["string", :integer], desc: 'ID or URL-encoded path of the project owned by a user'
      #       optional :search, type: :string, desc: "Return list of things matching the search criteria."
      #     end
      #
      #   # bad
      #     params do
      #       requires :current_file, type: "hash", desc: "File information for actions" do
      #         requires :file_name, type: :string, limit: 255, desc: 'The name of the current file'
      #         requires :content_above_cursor, type: "content", limit: MAX_CONTENT_SIZE, desc: 'Content above cursor'
      #         optional :content_below_cursor, type: Array[:string], desc: 'The content below cursor'
      #       end
      #     end
      #
      #   # good
      #     params do
      #       requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project owned by a user'
      #       optional :search,
      #         type: String,
      #         desc: "Return list of things matching the search criteria."
      #     end
      #
      #    # good
      #      params do
      #        requires :current_file, type: Hash, desc: "File information for actions" do
      #          requires :file_name, type: String, limit: 255, desc: 'The name of the current file'
      #          requires :content_above_cursor, type: String, limit: MAX_CONTENT_SIZE, desc: 'The content above cursor'
      #          optional :content_below_cursor, type: Array[String], desc: 'Content below cursor'
      #        end
      #      end
      #
      class ParameterType < RuboCop::Cop::Base
        include CodeReuseHelpers
        include APIHiddenParamHelpers
        extend NodePatternHelper

        # Grape::Validations::Types - https://github.com/ruby-grape/grape/blob/master/lib/grape/validations/types.rb
        PRIMITIVES = %w[Integer Float BigDecimal Numeric Date DateTime Time String Symbol Boolean Grape::API::Boolean
          TrueClass FalseClass].freeze
        STRUCTURES = %w[Hash Array Set].freeze
        SPECIAL = %w[JSON File Rack::Multipart::UploadedFile].freeze

        MSG = 'Invalid type or types. API params types must be one of Grape supported param types. https://docs.gitlab.com/development/api_styleguide#methods-and-parameters-description.'
        MISSING_TYPE = 'API parameter is missing type declaration.'
        DUPLICATE_TYPES = 'Duplicate type definitions. API params must only define one of type or types.'

        RESTRICT_ON_SEND = %i[requires optional].freeze

        # @!method custom_api_validation_type?(node)
        def_node_matcher :custom_api_validation_type?, <<~PATTERN
          (const #{const_pattern('API::Validations::Types')} ...)
        PATTERN

        # @!method coerced_type?(node)
        def_node_matcher :coerced_type?, <<~PATTERN
          (send _
            ...
            (hash <(pair (sym :coerce_with) _) ...>)
          )
        PATTERN

        # @!method type_option(node)
        def_node_matcher :type_option, <<~PATTERN
          (send _
            ...
            (hash <(pair (sym :type) $_) ...>)
          )
        PATTERN

        # @!method types_option(node)
        def_node_matcher :types_option, <<~PATTERN
          (send _
            ...
            (hash <(pair (sym :types) $_) ...>)
          )
        PATTERN

        def on_send(node)
          return if hidden_param?(node)

          type_value = type_option(node)
          types_value = types_option(node)
          is_coerced_type = coerced_type?(node)

          add_offense(node, message: DUPLICATE_TYPES) if types_value && type_value

          if type_value
            check_types(type_value, is_coerced_type)
          elsif types_value
            check_types(types_value, is_coerced_type)
          else
            add_offense(node, message: MISSING_TYPE)
          end
        end
        alias_method :on_csend, :on_send

        private

        def check_types(node, is_coerced_type)
          case node.type
          when :const
            # Accept custom API::Validations::Types
            return if custom_api_validation_type?(node)
            return if valid_grape_type?(node)
            return if is_coerced_type

            add_offense(node)
          when :array
            node.children.each { |el| check_types(el, is_coerced_type) }
          when :send
            add_offense(node) if node.receiver.nil? && node.arguments.empty?
            check_types(node.receiver, is_coerced_type) if node.receiver
            node.arguments.each { |arg| check_types(arg, is_coerced_type) }
          else
            add_offense(node)
          end
        end

        # validated types correspond to Grape::Validations::Types in source code
        # https://github.com/ruby-grape/grape/blob/master/lib/grape/validations/types.rb
        def valid_grape_type?(node)
          name = node.const_name
          PRIMITIVES.include?(name) || STRUCTURES.include?(name) || SPECIAL.include?(name)
        end
      end
    end
  end
end
