# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
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
          (block (send nil? $/^let_it_be/ (sym %name) ...) ...)
        PATTERN

        # @!method matching_let(node)
        def_node_matcher :matching_let, <<~PATTERN
          (block (send nil? {:let :let!} (sym %name) ...) ...)
        PATTERN

        # @!method before_block?(node)
        def_node_matcher :before_block?, <<~PATTERN
          (block (send nil? :before ...) ...)
        PATTERN

        # @!method object_calling_add_role_method(node)
        def_node_matcher :object_calling_add_role_method, <<~PATTERN
          (send (send nil? $_) %ROLE_METHODS ...)
        PATTERN

        def on_send(node)
          object_calling_add_role = object_calling_add_role_method(node)
          return unless object_calling_add_role

          before_block = before_block_ancestor(node)
          return unless before_block

          let_it_be = nearest_let_it_be(node, name: object_calling_add_role)
          return unless let_it_be

          message = format(MSG, let_it_be: let_it_be)
          add_offense(node, message: message)
        end

        private

        def before_block_ancestor(node)
          node.each_ancestor(:block).find { |block_node| before_block?(block_node) }
        end

        # Finds the declaration of `name` that RSpec would actually resolve
        # at runtime, walking outward from the nearest example group and
        # taking the last declaration in each scope (last-definition-wins).
        # We only flag it when that declaration is `let_it_be`-family; a
        # nearer `let`/`let!` shadows it and makes the offense a false
        # positive.
        #
        # @example
        #   let_it_be(:project) { create(:project) }
        #
        #   describe '#foo' do
        #     let(:project) { create(:project) } # shadows the let_it_be above
        #
        #     before { project.add_guest(guest) } # not flagged
        #   end
        def nearest_let_it_be(node, name:)
          node.each_ancestor.each do |parent_node|
            matches = parent_node.each_child_node(:block).filter_map do |child_node|
              classify_declaration(child_node, name: name)
            end
            next if matches.empty?

            declaration = matches.last
            return declaration unless declaration == :let

            return nil
          end

          nil
        end

        def classify_declaration(child_node, name:)
          matching_let_it_be(child_node, name: name) || (:let if matching_let(child_node, name: name))
        end
      end
    end
  end
end
