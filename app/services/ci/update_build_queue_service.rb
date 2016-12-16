module Ci
  class UpdateBuildQueueService < BaseService
    def execute(build)
      build.project.runners.select do |runner|
        if runner.can_pick?(build)
          runner.tick_update
        end
      end
    end
  end
end
