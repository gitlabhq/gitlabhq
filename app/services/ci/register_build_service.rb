module Ci
  # This class responsible for assigning
  # proper pending build to runner on runner API request
  class RegisterBuildService
    include CurrentSettings

    def execute(current_runner)
      builds = Ci::Build.pending.unstarted

      builds =
        if current_runner.shared?
          builds_for_shared_runner_with_build_minutes
        else
          builds_for_specific_runner
        end

      build = builds.find do |build|
        current_runner.can_pick?(build)
      end

      if build
        # In case when 2 runners try to assign the same build, second runner will be declined
        # with StateMachines::InvalidTransition or StaleObjectError when doing run! or save method.
        build.runner_id = current_runner.id
        build.run!
      end

      build

    rescue StateMachines::InvalidTransition, ActiveRecord::StaleObjectError
      nil
    end

    private

    def builds_for_shared_runner
      new_builds.
        # don't run projects which have not enabled shared runners and builds
        joins(:project).where(projects: { shared_runners_enabled: true }).
        joins('LEFT JOIN project_features ON ci_builds.gl_project_id = project_features.project_id').
        where('project_features.builds_access_level IS NULL or project_features.builds_access_level > 0').

        # select projects with allowed number of shared runner minutes
        joins('LEFT JOIN project_metrics ON ci_builds.gl_project_id = project_metrics.project_id').
        where('COALESCE(projects.shared_runner_minutes_limit, ?, 0) > 0 AND ' \
              'COALESCE(project_metrics.shared_runner_minutes, 0) < COALESCE(projects.shared_runner_minutes_limit, ?, 0)',
              current_application_settings.shared_runners_minutes)

        # this returns builds that are ordered by number of running builds
        # we prefer projects that don't use shared runners at all
        joins("LEFT JOIN (#{running_builds_for_shared_runners.to_sql}) AS project_builds ON ci_builds.gl_project_id=project_builds.gl_project_id").
        order('COALESCE(project_builds.running_builds, 0) ASC', 'ci_builds.id ASC')
    end

    def builds_for_specific_runner
      new_builds.where(project: current_runner.projects.with_builds_enabled).order('created_at ASC')
    end

    def running_builds_for_shared_runners
      Ci::Build.running.where(runner: Ci::Runner.shared).
        group(:gl_project_id).select(:gl_project_id, 'count(*) AS running_builds')
    end

    def new_builds
      Ci::Build.pending.unstarted
    end
  end
end
