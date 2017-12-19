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
      builds = builds_for_runner

      valid = true

      if Feature.enabled?('ci_job_request_with_tags_matcher')
        # pick builds that does not have other tags than runner's one
        builds = builds.matches_tag_ids(runner.tags.ids)

        # pick builds that have at least one tag
        unless runner.run_untagged?
          builds = builds.with_any_tags
        end
      end

      builds.find do |build|
        next unless runner.can_pick?(build)

        begin
          # In case when 2 runners try to assign the same build, second runner will be declined
          # with StateMachines::InvalidTransition or StaleObjectError when doing run! or save method.
          begin
            build.runner_id = runner.id
            build.run!
            register_success(build)

            return Result.new(build, true) # rubocop:disable Cop/AvoidReturnFromBlocks
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

    def builds_for_runner
      new_builds
        .joins("LEFT JOIN (#{running_projects.to_sql}) AS running_projects ON ci_builds.project_id=running_projects.project_id")
        .order('COALESCE(running_projects.running_builds, 0) ASC', 'ci_builds.id ASC')
    end

    # New builds from the accessible projects
    def new_builds
      filter_builds(Ci::Build.pending.unstarted)
    end

    # Count running builds from the accessible projects
    def running_projects
      filter_builds(Ci::Build.running)
        .group(:project_id).select(:project_id, 'count(*) AS running_builds')
    end

    # Filter the builds from the accessible projects
    def filter_builds(builds)
      builds = builds.ref_protected if runner.ref_protected?
      builds.where(project: runner.accessible_projects)
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
