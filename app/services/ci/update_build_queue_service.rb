# frozen_string_literal: true

module Ci
  class UpdateBuildQueueService
    def execute(build)
      tick_for(build, build.project.all_runners)
    end

    private

    def tick_for(build, runners)
      if Feature.enabled?(:ci_update_queues_for_online_runners, build.project, default_enabled: true)
        runners = runners.with_recent_runner_queue
      end

      runners.each do |runner|
        runner.pick_build!(build)
      end
    end
  end
end
