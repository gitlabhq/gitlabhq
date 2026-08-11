# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module Gitlab
      # Checks for use of User#organization method
      #
      # A User belongs to exactly one Organization (ADR 016: ownership via
      # organization_id is always exclusive), so deriving a sharding key or
      # attribution value from user.organization is not a shortcut around
      # Current.organization - it's the correct value. That still needs a local
      # RuboCop suppression comment explaining why, since this cop can't tell that
      # case apart from a real offense; see Gitlab::Llm::QAi::Client#ai_settings
      # for a worked example.
      #
      # @example
      #
      #   # bad
      #   class SomeService
      #     def execute
      #       do_something_with(user.organization)
      #     end
      #   end
      #
      #   # bad
      #   class SomeService
      #     def execute
      #       do_something_with(current_user.organization)
      #     end
      #   end
      #
      #   # good
      #   class SomeController < ApplicationController
      #     def create
      #       response = SomeService.new(organization: Current.organization).execute
      #     end
      #   end
      #
      #   class SomeService
      #     def initialize(organization:)
      #       @organization = organization
      #     end
      #
      #     def execute
      #       do_something_with(@organization)
      #     end
      #   end
      #
      #   # good (these are not User objects)
      #   project.organization
      #   group.organization
      #   namespace.organization
      #
      class AvoidUserOrganization < RuboCop::Cop::Base
        MSG =
          'Avoid calling `organization` on User objects. ' \
            'Instead, use `Current.organization` in controllers and pass the organization value down to other layers.'

        # @!method user_organization?(node)
        def_node_matcher :user_organization?, <<~PATTERN
          (call _ :organization)
        PATTERN

        def on_send(node)
          return unless user_organization?(node)
          return unless looks_like_user?(node.receiver)

          add_offense(node)
        end
        alias_method :on_csend, :on_send

        private

        def looks_like_user?(receiver)
          return false unless receiver

          name = extract_name(receiver)
          return false unless name
          return false if name.include?('organization_user')

          name == 'user' || name.end_with?('_user')
        end

        def extract_name(node)
          case node.type
          when :send
            node.method_name.to_s
          when :ivar, :lvar, :cvar
            node.children.first.to_s.gsub(/^@+/, '')
          end
        end
      end
    end
  end
end
