module Ci
  class UpdateBuildQueueService
    def execute(build)
      build.project.all_active_runners.find_each do |runner|
        if runner.can_pick?(build)
          Gitlab::Ci::Queueing::RunnerQueue.new(runner).enqueue(build)
          runner.tick_runner_queue
        end
      end
    end

    private

    def all_active_runners(build)
      build.project.all_active_runners
    end
  end
end
