# frozen_string_literal: true

module Ci
  # This class responsible for assigning
  # proper pending build to runner on runner API request
  class RegisterJobService
    attr_reader :runner, :metrics

    TEMPORARY_LOCK_TIMEOUT = 3.seconds

    Result = Struct.new(:build, :build_json, :valid?)

    ##
    # The queue depth limit number has been determined by observing 95
    # percentile of effective queue depth on gitlab.com. This is only likely to
    # affect 5% of the worst case scenarios.
    MAX_QUEUE_DEPTH = 45

    def initialize(runner)
      @runner = runner
      @metrics = ::Gitlab::Ci::Queue::Metrics.new(runner)
    end

    def execute(params = {})
      db_all_caught_up = ::Gitlab::Database::LoadBalancing::Sticking.all_caught_up?(:runner, runner.id)

      @metrics.increment_queue_operation(:queue_attempt)

      result = @metrics.observe_queue_time(:process, @runner.runner_type) do
        process_queue(params)
      end

      # Since we execute this query against replica it might lead to false-positive
      # We might receive the positive response: "hi, we don't have any more builds for you".
      # This might not be true. If our DB replica is not up-to date with when runner event was generated
      # we might still have some CI builds to be picked. Instead we should say to runner:
      # "Hi, we don't have any more builds now,  but not everything is right anyway, so try again".
      # Runner will retry, but again, against replica, and again will check if replication lag did catch-up.
      if !db_all_caught_up && !result.build
        metrics.increment_queue_operation(:queue_replication_lag)

        ::Ci::RegisterJobService::Result.new(nil, false) # rubocop:disable Cop/AvoidReturnFromBlocks
      else
        result
      end
    end

    private

    def process_queue(params)
      valid = true
      depth = 0

      each_build(params) do |build|
        depth += 1
        @metrics.increment_queue_operation(:queue_iteration)

        if depth > max_queue_depth
          @metrics.increment_queue_operation(:queue_depth_limit)

          valid = false

          break
        end

        # We read builds from replicas
        # It is likely that some other concurrent connection is processing
        # a given build at a given moment. To avoid an expensive compute
        # we perform an exclusive lease on Redis to acquire a build temporarily
        unless acquire_temporary_lock(build.id)
          @metrics.increment_queue_operation(:build_temporary_locked)

          # We failed to acquire lock
          # - our queue is not complete as some resources are locked temporarily
          # - we need to re-process it again to ensure that all builds are handled
          valid = false

          next
        end

        result = process_build(build, params)
        next unless result

        if result.valid?
          @metrics.register_success(result.build)
          @metrics.observe_queue_depth(:found, depth)

          return result # rubocop:disable Cop/AvoidReturnFromBlocks
        else
          # The usage of valid: is described in
          # handling of ActiveRecord::StaleObjectError
          valid = false
        end
      end

      @metrics.increment_queue_operation(:queue_conflict) unless valid
      @metrics.observe_queue_depth(:conflict, depth) unless valid
      @metrics.observe_queue_depth(:not_found, depth) if valid
      @metrics.register_failure

      Result.new(nil, nil, valid)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def each_build(params, &blk)
      queue = ::Ci::Queue::BuildQueueService.new(runner)

      builds = begin
        if runner.instance_type?
          queue.builds_for_shared_runner
        elsif runner.group_type?
          queue.builds_for_group_runner
        else
          queue.builds_for_project_runner
        end
      end

      if runner.ref_protected?
        builds = queue.builds_for_protected_runner(builds)
      end

      # pick builds that does not have other tags than runner's one
      builds = queue.builds_matching_tag_ids(builds, runner.tags.ids)

      # pick builds that have at least one tag
      unless runner.run_untagged?
        builds = queue.builds_with_any_tags(builds)
      end

      # pick builds that older than specified age
      if params.key?(:job_age)
        builds = queue.builds_queued_before(builds, params[:job_age].seconds.ago)
      end

      build_ids = retrieve_queue(-> { queue.execute(builds) })

      @metrics.observe_queue_size(-> { build_ids.size }, @runner.runner_type)

      build_ids.each { |build_id| yield Ci::Build.find(build_id) }
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def retrieve_queue(queue_query_proc)
      ##
      # We want to reset a load balancing session to discard the side
      # effects of writes that could have happened prior to this moment.
      #
      ::Gitlab::Database::LoadBalancing::Session.clear_session

      @metrics.observe_queue_time(:retrieve, @runner.runner_type) do
        queue_query_proc.call
      end
    end

    def process_build(build, params)
      unless build.pending?
        @metrics.increment_queue_operation(:build_not_pending)
        return
      end

      if runner.can_pick?(build)
        @metrics.increment_queue_operation(:build_can_pick)
      else
        @metrics.increment_queue_operation(:build_not_pick)

        return
      end

      # In case when 2 runners try to assign the same build, second runner will be declined
      # with StateMachines::InvalidTransition or StaleObjectError when doing run! or save method.
      if assign_runner!(build, params)
        present_build!(build)
      end
    rescue ActiveRecord::StaleObjectError
      # We are looping to find another build that is not conflicting
      # It also indicates that this build can be picked and passed to runner.
      # If we don't do it, basically a bunch of runners would be competing for a build
      # and thus we will generate a lot of 409. This will increase
      # the number of generated requests, also will reduce significantly
      # how many builds can be picked by runner in a unit of time.
      # In case we hit the concurrency-access lock,
      # we still have to return 409 in the end,
      # to make sure that this is properly handled by runner.
      @metrics.increment_queue_operation(:build_conflict_lock)

      Result.new(nil, nil, false)
    rescue StateMachines::InvalidTransition
      @metrics.increment_queue_operation(:build_conflict_transition)

      Result.new(nil, nil, false)
    rescue StandardError => ex
      @metrics.increment_queue_operation(:build_conflict_exception)

      # If an error (e.g. GRPC::DeadlineExceeded) occurred constructing
      # the result, consider this as a failure to be retried.
      scheduler_failure!(build)
      track_exception_for_build(ex, build)

      # skip, and move to next one
      nil
    end

    def max_queue_depth
      MAX_QUEUE_DEPTH
    end

    # Force variables evaluation to occur now
    def present_build!(build)
      # We need to use the presenter here because Gitaly calls in the presenter
      # may fail, and we need to ensure the response has been generated.
      presented_build = ::Ci::BuildRunnerPresenter.new(build) # rubocop:disable CodeReuse/Presenter
      build_json = ::API::Entities::Ci::JobRequest::Response.new(presented_build).to_json
      Result.new(build, build_json, true)
    end

    def assign_runner!(build, params)
      build.runner_id = runner.id
      build.runner_session_attributes = params[:session] if params[:session].present?

      failure_reason, _ = pre_assign_runner_checks.find { |_, check| check.call(build, params) }

      if failure_reason
        @metrics.increment_queue_operation(:runner_pre_assign_checks_failed)

        build.drop!(failure_reason)
      else
        @metrics.increment_queue_operation(:runner_pre_assign_checks_success)

        build.run!
      end

      !failure_reason
    end

    def acquire_temporary_lock(build_id)
      return true unless Feature.enabled?(:ci_register_job_temporary_lock, runner)

      key = "build/register/#{build_id}"

      Gitlab::ExclusiveLease
        .new(key, timeout: TEMPORARY_LOCK_TIMEOUT.to_i)
        .try_obtain
    end

    def scheduler_failure!(build)
      Gitlab::OptimisticLocking.retry_lock(build, 3, name: 'register_job_scheduler_failure') do |subject|
        subject.drop!(:scheduler_failure)
      end
    rescue StandardError => ex
      build.doom!

      # This requires extra exception, otherwise we would loose information
      # why we cannot perform `scheduler_failure`
      track_exception_for_build(ex, build)
    end

    def track_exception_for_build(ex, build)
      Gitlab::ErrorTracking.track_exception(ex,
        build_id: build.id,
        build_name: build.name,
        build_stage: build.stage,
        pipeline_id: build.pipeline_id,
        project_id: build.project_id
      )
    end

    def pre_assign_runner_checks
      {
        missing_dependency_failure: -> (build, _) { !build.has_valid_build_dependencies? },
        runner_unsupported: -> (build, params) { !build.supported_runner?(params.dig(:info, :features)) },
        archived_failure: -> (build, _) { build.archived? }
      }
    end
  end
end

Ci::RegisterJobService.prepend_mod_with('Ci::RegisterJobService')
