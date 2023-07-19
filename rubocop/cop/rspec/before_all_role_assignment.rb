# frozen_string_literal: true

require 'rubocop-rspec'

module Rubocop
  module Cop
    module RSpec
      # Checks for let_it_be with before instead of before_all when using `add_*` methods
      #
      # @example
      #
      #   # bad
      #   let_it_be(:project) { create(:project) }
      #   let_it_be(:guest) { create(:user) }
      #
      #   before do
      #     project.add_guest(guest)
      #   end
      #
      #   # good
      #   let_it_be(:project) { create(:project) }
      #   let_it_be(:guest) { create(:user) }
      #
      #   before_all do
      #     project.add_guest(guest)
      #   end
      class BeforeAllRoleAssignment < RuboCop::Cop::RSpec::Base
        MSG = "Use `before_all` when used with `%{let_it_be}`."

        ROLE_METHODS = %i[add_guest add_reporter add_developer add_maintainer add_owner add_role].to_set.freeze

        RESTRICT_ON_SEND = ROLE_METHODS

        # @!method matching_let_it_be(node)
        def_node_matcher :matching_let_it_be, <<~PATTERN
          (block (send nil? $/^let_it_be/ (sym %name)) ...)
        PATTERN

        # @!method before_block?(node)
        def_node_matcher :before_block?, <<~PATTERN
          (block (send nil? :before ...) ...)
        PATTERN

        def_node_matcher :object_calling_add_role_method, <<~PATTERN
          (send (send nil? $_) %ROLE_METHODS ...)
        PATTERN

        def on_send(node)
          object_calling_add_role = object_calling_add_role_method(node)
          return unless object_calling_add_role

          before_block = before_block_ancestor(node)
          return unless before_block

          each_block_node_in_ancestor(node) do |child_node|
            matching_let_it_be(child_node, name: object_calling_add_role) do |let_it_be|
              message = format(MSG, let_it_be: let_it_be)
              add_offense(node, message: message)
            end
          end
        end

        private

        def before_block_ancestor(node)
          node.each_ancestor(:block).find { |block_node| before_block?(block_node) }
        end

        def each_block_node_in_ancestor(node, &block)
          node.each_ancestor do |parent_node|
            parent_node.each_child_node(:block, &block)
          end
        end
      end
    end
  end
end
