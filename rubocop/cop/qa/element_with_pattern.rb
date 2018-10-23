require_relative '../../qa_helpers'

module RuboCop
  module Cop
    module QA
      # This cop checks for the usage of factories in migration specs
      #
      # @example
      #
      #   # bad
      #   let(:user) { create(:user) }
      #
      #   # good
      #   let(:users) { table(:users) }
      #   let(:user) { users.create!(name: 'User 1', username: 'user1') }
      class ElementWithPattern < RuboCop::Cop::Cop
        include QAHelpers

        MESSAGE = "Don't use a pattern for element, create a corresponding `%s` instead.".freeze

        def on_send(node)
          return unless in_qa_file?(node)
          return unless method_name(node).to_s == 'element'

          element_name, pattern = node.arguments
          return unless pattern

          add_offense(node, location: pattern.source_range, message: MESSAGE % "qa-#{element_name.value.to_s.tr('_', '-')}")
        end

        private

        def method_name(node)
          node.children[1]
        end
      end
    end
  end
end
