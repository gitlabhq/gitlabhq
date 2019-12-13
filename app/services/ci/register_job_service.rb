# frozen_string_literal: true

module Ci
  # This class responsible for assigning
  # proper pending build to runner on runner API request
  class RegisterJobService
    attr_reader :runner

    JOB_QUEUE_DURATION_SECONDS_BUCKETS = [1, 3, 10, 30, 60, 300, 900, 1800, 3600].freeze
    JOBS_RUNNING_FOR_PROJECT_MAX_BUCKET = 5.freeze

    Result = Struct.new(:build, :valid?)

    def initialize(runner)
      @runner = runner
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def execute(params = {})
      builds =
        if runner.instance_type?
          builds_for_shared_runner
        elsif runner.group_type?
          builds_for_group_runner
        else
          builds_for_project_runner
        end

      valid = true

      # pick builds that does not have other tags than runner's one
      builds = builds.matches_tag_ids(runner.tags.ids)

      # pick builds that have at least one tag
      unless runner.run_untagged?
        builds = builds.with_any_tags
      end

      # pick builds that older than specified age
      if params.key?(:job_age)
        builds = builds.queued_before(params[:job_age].seconds.ago)
      end

      builds.each do |build|
        result = process_build(build, params)
        next unless result

        if result.valid?
          register_success(result.build)

          return result
        else
          # The usage of valid: is described in
          # handling of ActiveRecord::StaleObjectError
          valid = false
        end
      end

      register_failure
      Result.new(nil, valid)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def process_build(build, params)
      return unless runner.can_pick?(build)

      # In case when 2 runners try to assign the same build, second runner will be declined
      # with StateMachines::InvalidTransition or StaleObjectError when doing run! or save method.
      if assign_runner!(build, params)
        Result.new(build, true)
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
      Result.new(nil, false)
    rescue => ex
      raise ex unless Feature.enabled?(:ci_doom_build, default_enabled: true)

      scheduler_failure!(build)
      track_exception_for_build(ex, build)

      # skip, and move to next one
      nil
    end

    def assign_runner!(build, params)
      build.runner_id = runner.id
      build.runner_session_attributes = params[:session] if params[:session].present?

      unless build.has_valid_build_dependencies?
        build.drop!(:missing_dependency_failure)
        return false
      end

      unless build.supported_runner?(params.dig(:info, :features))
        build.drop!(:runner_unsupported)
        return false
      end

      if build.archived?
        build.drop!(:archived_failure)
        return false
      end

      build.run!
      true
    end

    def scheduler_failure!(build)
      Gitlab::OptimisticLocking.retry_lock(build, 3) do |subject|
        subject.drop!(:scheduler_failure)
      end
    rescue => ex
      build.doom!

      # This requires extra exception, otherwise we would loose information
      # why we cannot perform `scheduler_failure`
      track_exception_for_build(ex, build)
    end

    def track_exception_for_build(ex, build)
      Gitlab::Sentry.track_exception(ex,
        build_id: build.id,
        build_name: build.name,
        build_stage: build.stage,
        pipeline_id: build.pipeline_id,
        project_id: build.project_id
      )
    end

    # rubocop: disable CodeReuse/ActiveRecord
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
        .order(Arel.sql('COALESCE(project_builds.running_builds, 0) ASC'), 'ci_builds.id ASC')
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def builds_for_project_runner
      new_builds.where(project: runner.projects.without_deleted.with_builds_enabled).order('id ASC')
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def builds_for_group_runner
      # Workaround for weird Rails bug, that makes `runner.groups.to_sql` to return `runner_id = NULL`
      groups = ::Group.joins(:runner_namespaces).merge(runner.runner_namespaces)

      hierarchy_groups = Gitlab::ObjectHierarchy.new(groups).base_and_descendants
      projects = Project.where(namespace_id: hierarchy_groups)
        .with_group_runners_enabled
        .with_builds_enabled
        .without_deleted
      new_builds.where(project: projects).order('id ASC')
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def running_builds_for_shared_runners
      Ci::Build.running.where(runner: Ci::Runner.instance_type)
        .group(:project_id).select(:project_id, 'count(*) AS running_builds')
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def new_builds
      builds = Ci::Build.pending.unstarted
      builds = builds.ref_protected if runner.ref_protected?
      builds
    end

    def register_failure
      failed_attempt_counter.increment
      attempt_counter.increment
    end

    def register_success(job)
      labels = { shared_runner: runner.instance_type?,
                 jobs_running_for_project: jobs_running_for_project(job) }

      job_queue_duration_seconds.observe(labels, Time.now - job.queued_at) unless job.queued_at.nil?
      attempt_counter.increment
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def jobs_running_for_project(job)
      return '+Inf' unless runner.instance_type?

      # excluding currently started job
      running_jobs_count = job.project.builds.running.where(runner: Ci::Runner.instance_type)
                              .limit(JOBS_RUNNING_FOR_PROJECT_MAX_BUCKET + 1).count - 1
      running_jobs_count < JOBS_RUNNING_FOR_PROJECT_MAX_BUCKET ? running_jobs_count : "#{JOBS_RUNNING_FOR_PROJECT_MAX_BUCKET}+"
    end
    # rubocop: enable CodeReuse/ActiveRecord

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

Ci::RegisterJobService.prepend_if_ee('EE::Ci::RegisterJobService')
