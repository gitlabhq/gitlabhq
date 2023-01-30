# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      module Handlers
        # This handler invokes Puma's graceful termination handler, which takes
        # into account a configurable grace period during which a process may
        # remain unresponsive to a SIGTERM.
        class PumaHandler
          def initialize(puma_options = ::Puma.cli_config.options)
            @worker = ::Puma::Cluster::WorkerHandle.new(0, $$, 0, puma_options)
          end

          def call
            @worker.term
            true
          end
        end
      end
    end
  end
end
