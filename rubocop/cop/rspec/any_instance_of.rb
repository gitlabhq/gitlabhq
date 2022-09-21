# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # This cop checks for `allow_any_instance_of` or `expect_any_instance_of`
      # usage in specs.
      #
      # @example
      #
      #   # bad
      #   allow_any_instance_of(User).to receive(:invalidate_issue_cache_counts)
      #
      #   # bad
      #   expect_any_instance_of(User).to receive(:invalidate_issue_cache_counts)
      #
      #   # good
      #   allow_next_instance_of(User) do |instance|
      #     allow(instance).to receive(:invalidate_issue_cache_counts)
      #   end
      #
      #   # good
      #   expect_next_instance_of(User) do |instance|
      #     expect(instance).to receive(:invalidate_issue_cache_counts)
      #   end
      #
      class AnyInstanceOf < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MESSAGE_EXPECT = 'Do not use `expect_any_instance_of` method, use `expect_next_instance_of` instead.'
        MESSAGE_ALLOW = 'Do not use `allow_any_instance_of` method, use `allow_next_instance_of` instead.'

        def_node_search :expect_any_instance_of?, <<~PATTERN
          (send (send nil? :expect_any_instance_of ...) ...)
        PATTERN
        def_node_search :allow_any_instance_of?, <<~PATTERN
          (send (send nil? :allow_any_instance_of ...) ...)
        PATTERN

        def on_send(node)
          if expect_any_instance_of?(node)
            add_offense(node, message: MESSAGE_EXPECT) do |corrector|
              corrector.replace(
                node.loc.expression,
                replacement_any_instance_of(node, 'expect')
              )
            end
          elsif allow_any_instance_of?(node)
            add_offense(node, message: MESSAGE_ALLOW) do |corrector|
              corrector.replace(
                node.loc.expression,
                replacement_any_instance_of(node, 'allow')
              )
            end
          end
        end

        private

        def replacement_any_instance_of(node, rspec_prefix)
          method_call =
            node.receiver.source.sub(
              "#{rspec_prefix}_any_instance_of",
              "#{rspec_prefix}_next_instance_of")

          block = <<~RUBY.chomp
            do |instance|
              #{rspec_prefix}(instance).#{node.method_name} #{node.children.last.source}
            end
          RUBY

          "#{method_call} #{block}"
        end
      end
    end
  end
end
