# frozen_string_literal: true

module Gitlab
  module PrinciplesDistiller
    class Sync
      # Generates the dynamic child pipeline that runs one distill job per affected principle, fanning back in to a
      # single collect job.
      #
      # Only the per-principle jobs are generated here; everything reviewable (image, before_script, timeout, artifacts,
      # the collect job, the Slack report job) lives in the static template this includes, so generated YAML stays a
      # thin routing layer rather than a second copy of the CI config.
      #
      # Concurrency is capped at MAX_CONCURRENT_DISTILLATIONS by assigning each principle a `resource_group` slot.
      # A resource group is a semaphore of exactly one, so N named groups give a cap of N.
      # Slots are assigned round-robin:
      # an unlucky slot with two slow principles serializes them, but each is still bounded by its own job timeout,
      # which is the property that matters.
      # Holding the cap where it is means this split adds zero load to the shared Duo Agent Platform scheduler; the win
      # is purely per-job timeout isolation and removing the batch barrier.
      class ChildPipeline
        # Deliberately NOT under `.gitlab/ci/*.gitlab-ci.yml`: that glob is
        # included by the root .gitlab-ci.yml, which would pull this child-only
        # template into every parent pipeline.
        TEMPLATE_PATH = '.gitlab/ci/sync-principles/child.gitlab-ci.yml'

        DISTILL_BASE_JOB = '.ai-principles-distill-base'

        COLLECT_JOB = 'ai-principles-collect'

        RESOURCE_GROUP_PREFIX = 'ai-principles-distill-slot'

        # Carries the affected-principle list from the generator to the collect job.
        # Collect needs the list it was SUPPOSED to receive in order to tell "job never ran" from "principle was never
        # affected": an absent artifact is only meaningful against an expected set.
        #
        # Passed as a variable rather than recomputed in the collect job so the two stages cannot disagree: recomputing
        # would silently re-derive the set from `--force` / `--only` flags the collect job was never given.
        EXPECTED_VARIABLE = 'AI_PRINCIPLES_EXPECTED'

        def initialize(principle_names, concurrency: Sync::MAX_CONCURRENT_DISTILLATIONS)
          @principle_names = principle_names
          @concurrency = concurrency
        end

        attr_reader :principle_names, :concurrency

        # A child pipeline needs at least one job, and the collect job comes from the included template, so a run with
        # no affected principles still yields a valid pipeline: collect runs, finds nothing, and reports a clean run.
        # That keeps the "everything is up to date" path identical to the single-job one rather than a special case.
        def to_yaml
          { 'include' => [{ 'local' => TEMPLATE_PATH }] }
            .merge(distill_jobs)
            .merge(COLLECT_JOB => collect_overrides)
            .to_yaml
        end

        private

        # The collect job itself is defined in the template; only the expected list (which is run-specific) is injected
        # here.
        def collect_overrides
          { 'variables' => { EXPECTED_VARIABLE => principle_names.join(',') } }
        end

        def distill_jobs
          principle_names.each_with_object({}).with_index do |(name, jobs), index|
            jobs["distill:#{name}"] = {
              'extends' => DISTILL_BASE_JOB,
              'resource_group' => "#{RESOURCE_GROUP_PREFIX}-#{index % concurrency}",
              'variables' => { 'AI_PRINCIPLE_NAME' => name }
            }
          end
        end
      end
    end
  end
end
