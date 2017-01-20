module Ci
  class UpdateBuildQueueService
    def execute(build)
      build.project.runners.each do |runner|
        if runner.can_pick?(build)
          runner.tick_runner_queue
        end
      end
    end
  end
end
