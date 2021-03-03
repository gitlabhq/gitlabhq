# frozen_string_literal: true

module Ci
  class UpdateBuildQueueService
    def execute(build, metrics = ::Gitlab::Ci::Queue::Metrics)
      tick_for(build, build.project.all_runners, metrics)
    end

    private

    def tick_for(build, runners, metrics)
      runners = runners.with_recent_runner_queue
      runners = runners.with_tags if Feature.enabled?(:ci_preload_runner_tags, default_enabled: :yaml)

      metrics.observe_active_runners(-> { runners.to_a.size })

      runners.each do |runner|
        metrics.increment_runner_tick(runner)

        runner.pick_build!(build)
      end
    end
  end
end
