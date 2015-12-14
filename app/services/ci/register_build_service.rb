module Ci
  # This class responsible for assigning
  # proper pending build to runner on runner API request
  class RegisterBuildService
    def execute(current_runner)
      builds = Ci::Build.pending.unstarted

      builds =
        if current_runner.shared?
          # don't run projects which have not enables shared runners
          builds.joins(:project).where(projects: { builds_enabled: true, shared_runners_enabled: true })
        else
          # do run projects which are only assigned to this runner
          builds.where(project: current_runner.projects.where(builds_enabled: true))
        end

      builds = builds.order('created_at ASC')

      build = builds.find do |build|
        build.can_be_served?(current_runner)
      end

      if build
        # In case when 2 runners try to assign the same build, second runner will be declined
        # with StateMachines::InvalidTransition in run! method.
        build.with_lock do
          build.runner_id = current_runner.id
          build.save!
          build.run!
        end
      end

      build

    rescue StateMachines::InvalidTransition
      nil
    end
  end
end
