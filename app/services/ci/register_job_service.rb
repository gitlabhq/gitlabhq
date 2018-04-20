module Ci
  # This class responsible for assigning
  # proper pending build to runner on runner API request
  class RegisterJobService
    attr_reader :runner

    JOB_QUEUE_DURATION_SECONDS_BUCKETS = [1, 3, 10, 30].freeze
    JOBS_RUNNING_FOR_PROJECT_MAX_BUCKET = 5.freeze

    Result = Struct.new(:build, :valid?)

    def initialize(runner)
      @runner = runner
    end

    def execute
      result = if Feature.enabled?('ci_redis_job_queueing')
        redis_execute
      else
        db_execute
      end

      result.tap do
        if result.build
          register_success(result.build)
        else
          register_failure
        end
      end
    end

    private

    def redis_execute
      runner_queue = Gitlab::Ci::Queueing::RunnerQueue.new(runner)

      result = Result.new(nil, true)
      
      until enqueued_job = runner_queue.dequeue
        build = Ci::Build.find_by(build_id)
        result = process_build!(build)
        runner_queue.remove!(enqueued_job) if result.valid?
        return result if result.build
      end

      result
    end

    def db_execute
      builds =
        if runner.shared?
          builds_for_shared_runner
        else
          builds_for_specific_runner
        end

      # pick builds that does not have other tags than runner's one
      builds = builds.matches_tag_ids(runner.tags.ids)

      # pick builds that have at least one tag
      unless runner.run_untagged?
        builds = builds.with_any_tags
      end

      result = Result.new(nil, true)

      builds.find do |build|
        result = process_build!(build)
        return result if result.build
      end

      result
    end

    def process_build!(build)
      unless runner.can_pick?(build)
        return Result.new(nil, true)
      end

      begin
        # In case when 2 runners try to assign the same build, second runner will be declined
        # with StateMachines::InvalidTransition or StaleObjectError when doing run! or save method.
        begin
          build.runner_id = runner.id
          build.run!

          return Result.new(build, true)
        rescue Ci::Build::MissingDependenciesError
          build.drop!(:missing_dependency_failure)
          return Result.new(nil, true)
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
        return Result.new(nil, false)
      end
    end

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
      labels = { shared_runner: runner.shared?,
                 jobs_running_for_project: jobs_running_for_project(job) }

      job_queue_duration_seconds.observe(labels, Time.now - job.queued_at) unless job.queued_at.nil?
      attempt_counter.increment
    end

    def jobs_running_for_project(job)
      return '+Inf' unless runner.shared?

      # excluding currently started job
      running_jobs_count = job.project.builds.running.where(runner: Ci::Runner.shared)
                              .limit(JOBS_RUNNING_FOR_PROJECT_MAX_BUCKET + 1).count - 1
      running_jobs_count < JOBS_RUNNING_FOR_PROJECT_MAX_BUCKET ? running_jobs_count : "#{JOBS_RUNNING_FOR_PROJECT_MAX_BUCKET}+"
    end

    def failed_attempt_counter
      @failed_attempt_counter ||= Gitlab::Metrics.counter(:job_register_attempts_failed_total, "Counts the times a runner tries to register a job")
    end

    def attempt_counter
      @attempt_counter ||= Gitlab::Metrics.counter(:job_register_attempts_total, "Counts the times a runner tries to register a job")
    end

    def job_queue_duration_seconds
      @job_queue_duration_seconds ||= Gitlab::Metrics.histogram(:job_queue_duration_seconds, 'Request handling execution time', {}, JOB_QUEUE_DURATION_SECONDS_BUCKETS)
    end
  end
end
