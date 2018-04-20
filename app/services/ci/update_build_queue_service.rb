module Ci
  class UpdateBuildQueueService
    def execute(build)
      build.project.runners.each do |runner|
        if runner.can_pick?(build)
          Gitlab::Ci::Queueing::RunnerQueue.new(runner).enqueue(build)
          runner.tick_runner_queue
        end
      end

      return unless build.project.shared_runners_enabled?

      Ci::Runner.shared.each do |runner|
        if runner.can_pick?(build)
          Gitlab::Ci::Queueing::RunnerQueue.new(runner).enqueue(build)
          runner.tick_runner_queue
        end
      end
    end
  end
end
