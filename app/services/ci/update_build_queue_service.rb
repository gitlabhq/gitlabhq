module Ci
  class UpdateBuildQueueService
    def execute(build)
      build.project.runners.each do |runner|
        if runner.can_pick?(build)
          runner.tick_runner_queue
        end
      end

      if build.project.group_runners_enabled?
        Ci::Runner.belonging_to_group(build.project_id).each do |runner|
          if runner.can_pick?(build)
            runner.tick_runner_queue
          end
        end
      end

      if build.project.shared_runners_enabled?
        Ci::Runner.shared.each do |runner|
          if runner.can_pick?(build)
            runner.tick_runner_queue
          end
        end
      end
    end
  end
end
