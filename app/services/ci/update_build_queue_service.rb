module Ci
  class UpdateBuildQueueService
    def execute(build)
      Ci::RunnerBuildsMatcherService.new.execute(build) do |runner|
        runner.pick_build!(build)
      end
    end
  end
end
