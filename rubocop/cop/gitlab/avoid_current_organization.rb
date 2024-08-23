# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module Gitlab
      # This cop checks for use Current.organization at banned layers of the application
      #
      # @example
      #
      # # bad
      # class SomeService
      #   def execute
      #     do_something_with(Current.organization)
      #   end
      # end
      #
      # # good
      # class SomeController < ApplicationController
      #   def create
      #     response = SomeService.new(organization: Current.organization).execute
      #   end
      # end
      #
      # class SomeService
      #   def initialize(organization:)
      #     @organization = organization
      #   end
      #
      #   def execute
      #     do_something_with(@organization)
      #   end
      # end
      #
      #
      class AvoidCurrentOrganization < RuboCop::Cop::Base
        MSG = 'Avoid the use of `%{name}` outside of approved application layers. ' \
              'Instead, pass the value down to those layers. ' \
              'See https://gitlab.com/gitlab-org/gitlab/-/issues/442751.'

        # @!method current_organization?(node)
        def_node_matcher :current_organization?, <<~PATTERN
          (send
            (const
              {nil? (cbase)} :Current) {:organization | :organization_id | :organization=} ...)
        PATTERN

        def on_send(node)
          return unless current_organization?(node)

          add_offense(node, message: format(MSG, name: node.method_name))
        end
      end
    end
  end
end
