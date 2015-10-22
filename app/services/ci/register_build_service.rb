module Ci
  # This class responsible for assigning
  # proper pending build to runner on runner API request
  class RegisterBuildService
    def execute(current_runner)
      builds = Ci::Build.pending.unstarted

      builds =
        if current_runner.shared?
          # don't run projects which have not enables shared runners
          builds.joins(commit: { gl_project: :gitlab_ci_project }).where(ci_projects: { shared_runners_enabled: true })
        else
          # do run projects which are only assigned to this runner
          builds.joins(:commit).where(ci_commits: { gl_project_id: current_runner.gl_projects_ids })
        end

      builds = builds.order('created_at ASC')

      build = builds.find do |build|
        build.can_be_served?(current_runner)
      end


      if build
        # In case when 2 runners try to assign the same build, second runner will be declined
        # with StateMachine::InvalidTransition in run! method.
        build.with_lock do
          build.runner_id = current_runner.id
          build.save!
          build.run!
        end
      end

      build

    rescue StateMachine::InvalidTransition
      nil
    end
  end
end
