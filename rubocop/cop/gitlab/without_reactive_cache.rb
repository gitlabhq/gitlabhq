# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Cop that prevents the use of `without_reactive_cache`
      class WithoutReactiveCache < RuboCop::Cop::Base
        MSG = 'without_reactive_cache is for debugging purposes only. Please use with_reactive_cache.'

        RESTRICT_ON_SEND = %i[without_reactive_cache].freeze

        def on_send(node)
          add_offense(node.loc.selector)
        end
      end
    end
  end
end
