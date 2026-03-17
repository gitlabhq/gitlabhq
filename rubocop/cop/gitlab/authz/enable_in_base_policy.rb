# frozen_string_literal: true

require 'rubocop'

module RuboCop
  module Cop
    module Gitlab
      module Authz
        # Forbid calling `enable` in BasePolicy.
        #
        # BasePolicy is inherited by all other policies. Enabling or preventing
        # abilities here is hard to reason about because it is unclear what resource
        # the ability will be authorized against. Prefer declaring abilities in the
        # concrete policy where the resource context is explicit.
        #
        # @example
        #   # bad
        #   enable :read_project
        #
        #   # good
        #   # (move these into the concrete policy that owns the resource)
        class EnableInBasePolicy < ::RuboCop::Cop::Base
          MSG = 'Do not call `enable` in BasePolicy. ' \
            'Move these into the concrete policy where the resource context is explicit.'

          RESTRICT_ON_SEND = %i[enable].freeze

          def on_send(node)
            add_offense(node.loc.selector)
          end

          def on_csend(node)
            on_send(node)
          end
        end
      end
    end
  end
end
