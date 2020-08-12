# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        # During the dry run we don't want to persist the pipeline and skip
        # all the other steps that operate on a persisted context.
        # This causes the chain to break at this point.
        class StopDryRun < Chain::Base
          def perform!
            # no-op
          end

          def break?
            @command.dry_run?
          end
        end
      end
    end
  end
end
