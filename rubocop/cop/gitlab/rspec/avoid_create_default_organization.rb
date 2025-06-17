# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module Gitlab
      module RSpec
        # Detects and disallows the use of the `:default` trait in FactoryBot calls.
        #
        # The `:default` trait is deprecated and should not be used in new code.
        # This helps maintain consistency across the test suite and prevents
        # potential issues with implicit defaults.
        #
        # @example
        #   # bad
        #   create(:organization, :default)
        #   build(:organization, :default)
        #   create(:organization, :admin, :default)
        #   create_list(:organization, 3, :default)
        #   create(:organization, :default, name: "Acme")
        #
        #   # good
        #   create(:organization)
        #   build(:organization)
        #   create(:organization, :admin)
        #   create_list(:organization, 3)
        #   create(:organization, name: "Acme")
        #
        # @safety
        #   This cop's autocorrection is marked as unsafe because removing the `:default`
        #   trait might change the behavior of the tests if they rely on the specific
        #   attributes set by that trait.
        #
        class AvoidCreateDefaultOrganization < RuboCop::Cop::Base
          MSG = "Do not use the `:default` trait when creating organizations"

          FACTORY_BOT_METHODS = %i[
            build build_list build_pair build_stubbed build_stubbed_list
            create create_list create_pair attributes_for attributes_for_list
            attributes_for_pair
          ].freeze

          def on_send(node)
            return unless factory_bot_method?(node)

            args = node.arguments.select(&:sym_type?)

            return if args.empty?
            return unless args.first.value == :organization

            # Check if any of other arguments is :default
            args.each do |arg|
              if arg.value == :default
                add_offense(node)
                break
              end
            end
          end
          alias_method :on_csend, :on_send

          private

          def factory_bot_method?(node)
            return false unless FACTORY_BOT_METHODS.include?(node.method_name)
            return false unless node.arguments.size > 1

            !node.receiver || (node.receiver.const_type? && node.receiver.const_name == 'FactoryBot')
          end
        end
      end
    end
  end
end
