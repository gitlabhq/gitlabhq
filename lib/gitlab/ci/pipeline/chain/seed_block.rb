# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class SeedBlock < Chain::Base
          include Chain::Helpers
          include Gitlab::Utils::StrongMemoize

          def perform!
            ##
            # Populate pipeline with block argument of CreatePipelineService#execute.
            #
            @command.seeds_block&.call(pipeline)

            raise "Pipeline cannot be persisted by `seeds_block`" if pipeline.persisted?
          end

          def break?
            pipeline.errors.any?
          end
        end
      end
    end
  end
end
