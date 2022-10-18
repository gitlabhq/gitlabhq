# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      module FactoryBot
        # This cop checks for the creation of ActiveRecord objects in serializers specs specs
        #
        # @example
        #
        #   # bad
        #   let(:user) { create(:user) }
        #   let(:users) { create_list(:user, 2) }
        #
        #   # good
        #   let(:user) { build_stubbed(:user) }
        #   let(:user) { build(:user) }
        #   let(:users) { build_stubbed_list(:user, 2) }
        #   let(:users) { build_list(:user, 2) }
        class AvoidCreate < RuboCop::Cop::Base
          MESSAGE = "Prefer using `build_stubbed` or similar over `%{method_name}`. See https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#optimize-factory-usage"
          FORBIDDEN_METHODS = %i[create create_list].freeze
          RESTRICT_ON_SEND = FORBIDDEN_METHODS

          def_node_matcher :forbidden_factory_usage, <<~PATTERN
            (
              send
              {(const nil? :FactoryBot) nil?}
              ${ #{FORBIDDEN_METHODS.map(&:inspect).join(' ')} }
              ...
              )
          PATTERN

          def on_send(node)
            method_name = forbidden_factory_usage(node)
            return unless method_name

            add_offense(node, message: format(MESSAGE, method_name: method_name))
          end
        end
      end
    end
  end
end
