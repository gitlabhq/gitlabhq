# frozen_string_literal: true

require 'rubocop-rspec'
require 'rubocop-factory_bot'

module RuboCop
  module Cop
    module RSpec
      module FactoryBot
        # Checks for FactoryBot strategy methods used in callbacks
        #
        # @example
        #   # bad
        #   factory :user do
        #     after(:build) do |user|
        #       create(:profile, user: user)
        #     end
        #   end
        #
        #   factory :project do
        #     before(:create) do |project|
        #       build(:namespace, project: project)
        #     end
        #   end
        #
        #   factory :issue do
        #     after(:stub) do |issue|
        #       create_list(:comment, 3, issue: issue)
        #     end
        #   end
        #
        #   # good
        #   factory :user do
        #     association :profile
        #   end
        #
        #   factory :project do
        #     association :namespace
        #   end
        #
        #   factory :issue do
        #     transient do
        #       comments_count { 3 }
        #     end
        #
        #     after(:create) do |issue, evaluator|
        #       issue.comments = evaluator.comments_count.times.map do
        #         association(:comment, issue: issue)
        #       end
        #     end
        #   end
        class StrategyInCallback < RuboCop::Cop::Base
          include RuboCop::FactoryBot::Language

          MSG = 'Prefer inline `association` over `%{type}`. ' \
            'See https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#factories'

          FORBIDDEN_METHODS = %i[build build_list build_stubbed build_stubbed_list create create_list].freeze

          # @!method forbidden_factory_usage(node)
          def_node_matcher :forbidden_factory_usage, <<~PATTERN
            (block
              (send nil? { :after :before } (sym _strategy))
              _args
              ` # in all descandents
              (send
                { nil? #factory_bot? }
                ${ #{FORBIDDEN_METHODS.map(&:inspect).join(' ')} }
                (sym _factory_name)
                ...
              )
            )
          PATTERN

          RESTRICT_ON_SEND = FORBIDDEN_METHODS

          def on_send(node)
            parent = node.each_ancestor(:block).first

            strategy = forbidden_factory_usage(parent)
            return unless strategy

            add_offense(node, message: format(MSG, type: strategy))
          end
        end
      end
    end
  end
end
