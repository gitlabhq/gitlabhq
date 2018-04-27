module Ci
  class UpdateBuildQueueService
    def execute(build)
      tick_for(build, build.project.runners)

      if build.project.group_runners_enabled?
        tick_for(build, Ci::Runner.belonging_to_parent_group_of_project(build.project_id))
      end

      if build.project.shared_runners_enabled?
        tick_for(build, Ci::Runner.shared)
      end
    end

    private

    def tick_for(build, runners)
      runners.each do |runner|
        runner.invalidate_build_cache!(build)
      end
    end
  end
end
