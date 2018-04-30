module Ci
  class UpdateBuildQueueService
    def execute(build)
      tick_for(build, build.project.all_runners)
    end

    private

    def tick_for(build, runners)
      runners.each do |runner|
        runner.invalidate_build_cache!(build)
      end
    end
  end
end
