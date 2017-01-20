module Ci
  class UpdateBuildQueueService
    def execute(build)
      build.project.runners.each do |runner|
        if runner.can_pick?(build)
          runner.tick_runner_queue
        end
      end

      Ci::Runner.shared.each do |runner|
        if runner.can_pick?(build)
          runner.tick_runner_queue
        end
      end if build.project.shared_runners_enabled?
    end
  end
end
