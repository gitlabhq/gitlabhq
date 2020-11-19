# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class SeedBlock < Chain::Base
          include Chain::Helpers
          include Gitlab::Utils::StrongMemoize

          def perform!
            return unless ::Gitlab::Ci::Features.seed_block_run_before_workflow_rules_enabled?(project)

            ##
            # Populate pipeline with block argument of CreatePipelineService#execute.
            #
            @command.seeds_block&.call(pipeline)

            raise "Pipeline cannot be persisted by `seeds_block`" if pipeline.persisted?
          end

          def break?
            return false unless ::Gitlab::Ci::Features.seed_block_run_before_workflow_rules_enabled?(project)

            pipeline.errors.any?
          end
        end
      end
    end
  end
end
