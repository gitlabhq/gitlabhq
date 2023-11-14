# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module Gitlab
      # This cop checks for use of gitlab instance specific checks.
      #
      # @example
      #
      #   # bad
      #   if Gitlab.com?
      #     Ci::Runner::FORM_EDITABLE + Ci::Runner::MINUTES_COST_FACTOR_FIELDS
      #   else
      #     Ci::Runner::FORM_EDITABLE
      #   end
      #
      #   # good
      #   if Gitlab::Saas.feature_available?(:purchases_additional_minutes)
      #     Ci::Runner::FORM_EDITABLE + Ci::Runner::MINUTES_COST_FACTOR_FIELDS
      #   else
      #     Ci::Runner::FORM_EDITABLE
      #   end
      #
      class AvoidGitlabInstanceChecks < RuboCop::Cop::Base
        MSG = 'Avoid the use of `%{name}`. Use Gitlab::Saas.feature_available?. ' \
              'See https://docs.gitlab.com/ee/development/ee_features.html#saas-only-feature'
        RESTRICT_ON_SEND = %i[
          com? com_except_jh? com_and_canary? com_but_not_canary? org_or_com? should_check_namespace_plan? enabled?
        ].freeze

        # @!method gitlab?(node)
        def_node_matcher :gitlab?, <<~PATTERN
          (send (const {nil? (cbase)} :Gitlab) ...)
        PATTERN

        # @!method should_check_namespace_plan?(node)
        def_node_matcher :should_check_namespace_plan?, <<~PATTERN
          (send
            (const
              (const
                {nil? (cbase)} :Gitlab) :CurrentSettings) :should_check_namespace_plan?)
        PATTERN

        # @!method saas_enabled?(node)
        def_node_matcher :saas_enabled?, <<~PATTERN
          (send
            (const
              (const
                {nil? (cbase)} :Gitlab) :Saas) :enabled?)
        PATTERN

        def on_send(node)
          return unless gitlab?(node) || should_check_namespace_plan?(node) || saas_enabled?(node)

          add_offense(node, message: format(MSG, name: node.method_name))
        end
      end
    end
  end
end
