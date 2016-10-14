module Ci
  # This class responsible for assigning
  # proper pending build to runner on runner API request
  class RegisterBuildService
    def execute(current_runner)
      builds = Ci::Build.pending.unstarted

      builds =
        if current_runner.shared?
          builds.
            # don't run projects which have not enabled shared runners and builds
            joins(:project).where(projects: { shared_runners_enabled: true }).
            joins('LEFT JOIN project_features ON ci_builds.gl_project_id = project_features.project_id').

            # this returns builds that are ordered by number of running builds
            # we prefer projects that don't use shared runners at all
            joins("LEFT JOIN (#{running_builds_for_shared_runners.to_sql}) AS project_builds ON ci_builds.gl_project_id=project_builds.gl_project_id").
            where('project_features.builds_access_level IS NULL or project_features.builds_access_level > 0').
            order('COALESCE(project_builds.running_builds, 0) ASC', 'ci_builds.id ASC')
        else
          # do run projects which are only assigned to this runner (FIFO)
          builds.where(project: current_runner.projects.with_builds_enabled).order('created_at ASC')
        end

      build = builds.find do |build|
        current_runner.can_pick?(build)
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

    def running_builds_for_shared_runners
      Ci::Build.running.where(runner: Ci::Runner.shared).
        group(:gl_project_id).select(:gl_project_id, 'count(*) AS running_builds')
    end
  end
end
