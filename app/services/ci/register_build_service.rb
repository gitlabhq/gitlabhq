module Ci
  # This class responsible for assigning
  # proper pending build to runner on runner API request
  class RegisterBuildService
    include Gitlab::CurrentSettings

    attr_reader :runner

    def initialize(runner)
      @runner = runner
    end

    def execute
      builds =
        if runner.shared?
          if ENV['DISABLE_SHARED_RUNNER_BUILD_MINTUES_LIMIT'].to_s == 'true'
            builds_for_shared_runner
          else
            builds_for_sharer_runner_with_build_minutes_check
          end
        else
          builds_for_specific_runner
        end

      build = builds.find do |build|
        runner.can_pick?(build)
      end

      if build
        # In case when 2 runners try to assign the same build, second runner will be declined
        # with StateMachines::InvalidTransition or StaleObjectError when doing run! or save method.
        build.runner_id = runner.id
        build.run!
      end

      build

    rescue StateMachines::InvalidTransition, ActiveRecord::StaleObjectError
      nil
    end

    private

    def builds_for_sharer_runner_with_build_minutes_check
      # select projects which have allowed number of shared runner minutes or are public
      builds_for_shared_runner.
        where("projects.visibility_level=? OR (#{builds_check_limit.to_sql})=1",
          Gitlab::VisibilityLevel::PUBLIC).
    end

    def builds_for_shared_runner
      new_builds.
        # don't run projects which have not enabled shared runners and builds
        joins(:project).where(projects: { shared_runners_enabled: true }).
        joins('LEFT JOIN project_features ON ci_builds.gl_project_id = project_features.project_id').
        where('project_features.builds_access_level IS NULL or project_features.builds_access_level > 0').

        # Implement fair scheduling
        # this returns builds that are ordered by number of running builds
        # we prefer projects that don't use shared runners at all
        joins("LEFT JOIN (#{running_builds_for_shared_runners.to_sql}) AS project_builds ON ci_builds.gl_project_id=project_builds.gl_project_id").
        order('COALESCE(project_builds.running_builds, 0) ASC', 'ci_builds.id ASC')
    end

    def builds_check_limit
      Namespace.reorder(nil).
        where("namespaces.id = projects.namespace_id").
        joins('LEFT JOIN namespace_metrics ON namespace_metrics.namespace_id = namespaces.id').
        where('COALESCE(namespaces.shared_runners_minutes_limit, ?, 0) = 0 OR ' \
          'COALESCE(namespace_metrics.shared_runners_minutes, 0) < COALESCE(namespaces.shared_runners_minutes_limit, ?, 0)',
          application_shared_runners_minutes, application_shared_runners_minutes).
        select('1')
    end

    def application_shared_runners_minutes
      current_application_settings.shared_runners_minutes
    end

    def builds_for_specific_runner
      new_builds.where(project: runner.projects.with_builds_enabled).order('created_at ASC')
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
