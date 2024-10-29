# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      module FactoryBot
        # This cop encourages the use of inline associations in FactoryBot.
        # The explicit use of `create` and `build` is discouraged.
        #
        # See https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#inline-definition
        #
        # @example
        #
        # Context:
        #
        #   Factory.define do
        #     factory :project, class: 'Project'
        #       # EXAMPLE below
        #     end
        #   end
        #
        # # bad
        # creator { create(:user) }
        # creator { create(:user, :admin) }
        # creator { build(:user) }
        # creator { FactoryBot.build(:user) }
        # creator { ::FactoryBot.build(:user) }
        # add_attribute(:creator) { build(:user) }
        #
        # # good
        # creator { association(:user) }
        # creator { association(:user, :admin) }
        # add_attribute(:creator) { association(:user) }
        #
        # # Accepted
        # after(:build) do |instance|
        #   instance.creator = create(:user)
        # end
        #
        # initialize_with do
        #   create(:project)
        # end
        #
        # creator_id { create(:user).id }
        #
        class InlineAssociation < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          MSG = 'Prefer inline `association` over `%{type}`. ' \
            'See https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#factories'

          REPLACEMENT = 'association'

          def_node_matcher :create_or_build, <<~PATTERN
            (
              send
              ${ nil? (const { nil? (cbase) } :FactoryBot) }
              ${ :create :build }
              (sym _)
              ...
            )
          PATTERN

          def_node_matcher :association_definition, <<~PATTERN
            (block
              {
                (send nil? $_)
                (send nil? :add_attribute (sym $_))
              }
              ...
            )
          PATTERN

          def_node_matcher :chained_call?, <<~PATTERN
            (send _ _)
          PATTERN

          SKIP_NAMES = %i[initialize_with].to_set.freeze

          def on_send(node)
            _receiver, type = create_or_build(node)
            return unless type
            return if chained_call?(node.parent)
            return unless inside_assocation_definition?(node)

            add_offense(node, message: format(MSG, type: type)) do |corrector|
              receiver, type = create_or_build(node)
              receiver = "#{receiver.source}." if receiver
              expression = "#{receiver}#{type}"
              replacement = node.source.sub(expression, REPLACEMENT)
              corrector.replace(node.source_range, replacement)
            end
          end

          private

          def inside_assocation_definition?(node)
            node.each_ancestor(:block).any? do |parent|
              name = association_definition(parent)
              name && !SKIP_NAMES.include?(name)
            end
          end
        end
      end
    end
  end
end
