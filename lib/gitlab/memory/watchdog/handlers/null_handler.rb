# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      module Handlers
        # This handler does nothing. It returns `false` to indicate to the
        # caller that the situation has not been dealt with so it will
        # receive calls repeatedly if fragmentation remains high.
        #
        # This is useful for "dress rehearsals" in production since it allows
        # us to observe how frequently the handler is invoked before taking action.
        class NullHandler
          include Singleton

          def call
            # NOP
            false
          end
        end
      end
    end
  end
end
