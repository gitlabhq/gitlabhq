# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # Checks for the usage of factories in migration specs
      #
      # @example
      #   # bad
      #   let(:user) { create(:user) }
      #   let(:project) { build(:project) }
      #   let(:issues) { create_list(:issue, 3) }
      #   let(:users) { build_list(:user, 2) }
      #   let(:user_attrs) { attributes_for(:user) }
      #
      #   before do
      #     FactoryBot.create(:user, name: 'Test User')
      #   end
      #
      #   # good
      #   let(:users) { table(:users) }
      #   let(:projects) { table(:projects) }
      #   let(:issues) { table(:issues) }
      #
      #   let(:user) { users.create!(name: 'User 1', username: 'user1') }
      #   let(:project) { projects.create!(name: 'Test Project', path: 'test-project') }
      #
      #   before do
      #     3.times { |i| issues.create!(title: "Issue #{i}", project_id: project.id) }
      #   end
      class FactoriesInMigrationSpecs < RuboCop::Cop::Base
        MESSAGE = "Don't use FactoryBot.%s in migration specs, use `table` instead."
        FORBIDDEN_METHODS = %i[build build_list create create_list attributes_for].freeze

        # @!method forbidden_factory_usage?(node)
        def_node_search :forbidden_factory_usage?, <<~PATTERN
          (send {(const nil? :FactoryBot) nil?} {#{FORBIDDEN_METHODS.map(&:inspect).join(' ')}} _ ...)
        PATTERN

        # Following is what node.children looks like on a match:
        # - Without FactoryBot namespace: [nil, :build, s(:sym, :user)]
        # - With FactoryBot namespace: [s(:const, nil, :FactoryBot), :build, s(:sym, :user)]
        def on_send(node)
          return unless forbidden_factory_usage?(node)

          method = node.children[1]

          add_offense(node, message: MESSAGE % method)
        end
      end
    end
  end
end
