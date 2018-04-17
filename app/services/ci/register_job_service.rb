module Ci
  # This class responsible for assigning
  # proper pending build to runner on runner API request
  class RegisterJobService
    attr_reader :runner

    Result = Struct.new(:build, :valid?)

    def initialize(runner)
      @runner = runner
    end

    def execute
      builds =
        if runner.shared?
          builds_for_shared_runner
        else
          builds_for_specific_runner
        end

      valid = true

      if Feature.enabled?('ci_job_request_with_tags_matcher')
        # pick builds that does not have other tags than runner's one
        builds = builds.matches_tag_ids(runner.tags.ids)

        # pick builds that have at least one tag
        unless runner.run_untagged?
          builds = builds.with_any_tags
        end
      end

      builds.auto_include(false).find do |build|
        next unless runner.can_pick?(build)

        begin
          # In case when 2 runners try to assign the same build, second runner will be declined
          # with StateMachines::InvalidTransition or StaleObjectError when doing run! or save method.
          begin
            build.runner_id = runner.id
            build.run!
            register_success(build)

            return Result.new(build, true)
          rescue Ci::Build::MissingDependenciesError
            build.drop!(:missing_dependency_failure)
          end
        rescue StateMachines::InvalidTransition, ActiveRecord::StaleObjectError
          # We are looping to find another build that is not conflicting
          # It also indicates that this build can be picked and passed to runner.
          # If we don't do it, basically a bunch of runners would be competing for a build
          # and thus we will generate a lot of 409. This will increase
          # the number of generated requests, also will reduce significantly
          # how many builds can be picked by runner in a unit of time.
          # In case we hit the concurrency-access lock,
          # we still have to return 409 in the end,
          # to make sure that this is properly handled by runner.
          valid = false
        end
      end

      register_failure
      Result.new(nil, valid)
    end

    private

    def builds_for_shared_runner
      new_builds.
        # don't run projects which have not enabled shared runners and builds
        joins(:project).where(projects: { shared_runners_enabled: true, pending_delete: false })
        .joins('LEFT JOIN project_features ON ci_builds.project_id = project_features.project_id')
        .where('project_features.builds_access_level IS NULL or project_features.builds_access_level > 0').

        # Implement fair scheduling
        # this returns builds that are ordered by number of running builds
        # we prefer projects that don't use shared runners at all
        joins("LEFT JOIN (#{running_builds_for_shared_runners.to_sql}) AS project_builds ON ci_builds.project_id=project_builds.project_id")
        .order('COALESCE(project_builds.running_builds, 0) ASC', 'ci_builds.id ASC')
    end

    def builds_for_specific_runner
      new_builds.where(project: runner.projects.without_deleted.with_builds_enabled).order('created_at ASC')
    end

    def running_builds_for_shared_runners
      Ci::Build.running.where(runner: Ci::Runner.shared)
        .group(:project_id).select(:project_id, 'count(*) AS running_builds')
    end

    def new_builds
      builds = Ci::Build.pending.unstarted
      builds = builds.ref_protected if runner.ref_protected?
      builds
    end

    def shared_runner_build_limits_feature_enabled?
      ENV['DISABLE_SHARED_RUNNER_BUILD_MINUTES_LIMIT'].to_s != 'true'
    end

    def register_failure
      failed_attempt_counter.increment
      attempt_counter.increment
    end

    def register_success(job)
      job_queue_duration_seconds.observe({ shared_runner: @runner.shared? }, Time.now - job.created_at)
      attempt_counter.increment
    end

    def failed_attempt_counter
      @failed_attempt_counter ||= Gitlab::Metrics.counter(:job_register_attempts_failed_total, "Counts the times a runner tries to register a job")
    end

    def attempt_counter
      @attempt_counter ||= Gitlab::Metrics.counter(:job_register_attempts_total, "Counts the times a runner tries to register a job")
    end

    def job_queue_duration_seconds
      @job_queue_duration_seconds ||= Gitlab::Metrics.histogram(:job_queue_duration_seconds, 'Request handling execution time')
    end
  end
end
