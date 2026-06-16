# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module Gitlab
      # Checks for use of raw GitLab Dedicated instance checks.
      #
      # @example
      #
      #   # bad
      #   if Gitlab::CurrentSettings.gitlab_dedicated_instance?
      #     do_dedicated_specific_thing
      #   end
      #
      #   # bad
      #   return unless Gitlab::Dedicated.dedicated_instance?
      #
      #   # good
      #   if Gitlab::Dedicated.feature_available?(:my_dedicated_feature)
      #     do_dedicated_specific_thing
      #   end
      #
      class AvoidGitlabDedicatedInstanceChecks < RuboCop::Cop::Base
        MSG = 'Avoid the use of `%{name}`. Use Gitlab::Dedicated.feature_available?. ' \
          'Instance checks create untested code paths since they are false by default in tests. ' \
          'See https://docs.gitlab.com/development/ee_features/#dedicated-instance-features'

        RESTRICT_ON_SEND = %i[gitlab_dedicated_instance? dedicated_instance?].freeze

        # @!method current_settings_dedicated?(node)
        def_node_matcher :current_settings_dedicated?, <<~PATTERN
          (send
            (const
              (const
                {nil? (cbase)} :Gitlab) :CurrentSettings) :gitlab_dedicated_instance?)
        PATTERN

        # @!method dedicated_module_check?(node)
        def_node_matcher :dedicated_module_check?, <<~PATTERN
          (send
            (const
              (const
                {nil? (cbase)} :Gitlab) :Dedicated) :dedicated_instance?)
        PATTERN

        def on_send(node)
          return unless current_settings_dedicated?(node) || dedicated_module_check?(node)

          add_offense(node, message: format(MSG, name: node.source))
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
