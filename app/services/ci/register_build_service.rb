module Ci
  # This class responsible for assigning
  # proper pending build to runner on runner API request
  class RegisterBuildService
    def execute(current_runner)
      builds = Ci::Build.pending.unstarted

      builds =
        if current_runner.shared?
          # this returns builds that are ordered by number of running builds
          # we prefer projects that don't use shared runners at all
          builds.joins("JOIN (#{projects_with_builds_for_shared_runners.to_sql}) AS projects ON ci_builds.gl_project_id=projects.gl_project_id").
            order('projects.running_builds ASC', 'ci_builds.id ASC')
        else
          # do run projects which are only assigned to this runner (FIFO)
          builds.where(project: current_runner.projects.where(builds_enabled: true)).order('created_at ASC')
        end

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

    private

    def projects_with_builds_for_shared_runners
      Ci::Build.running_or_pending.
        joins(:project).where(projects: { builds_enabled: true, shared_runners_enabled: true }).
        group(:gl_project_id).
        select(:gl_project_id, "count(case when status = 'running' AND runner_id = (#{shared_runners.to_sql}) then 1 end) as running_builds")
    end

    def shared_runners
      Ci::Runner.shared.select(:id)
    end
  end
end
