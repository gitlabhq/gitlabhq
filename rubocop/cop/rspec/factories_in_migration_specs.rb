require_relative '../../spec_helpers'

module RuboCop
  module Cop
    module RSpec
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
      class FactoriesInMigrationSpecs < RuboCop::Cop::Cop
        include SpecHelpers

        MESSAGE = "Don't use FactoryBot.%s in migration specs, use `table` instead.".freeze
        FORBIDDEN_METHODS = %i[build build_list create create_list].freeze

        def_node_search :forbidden_factory_usage?, <<~PATTERN
          (send {(const nil? :FactoryBot) nil?} {#{FORBIDDEN_METHODS.map(&:inspect).join(' ')}} ...)
        PATTERN

        # Following is what node.children looks like on a match:
        # - Without FactoryBot namespace: [nil, :build, s(:sym, :user)]
        # - With FactoryBot namespace: [s(:const, nil, :FactoryBot), :build, s(:sym, :user)]
        def on_send(node)
          return unless in_migration_spec?(node)
          return unless forbidden_factory_usage?(node)

          method = node.children[1]

          add_offense(node, location: :expression, message: MESSAGE % method)
        end
      end
    end
  end
end
