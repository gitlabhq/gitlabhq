# frozen_string_literal: true

module Ci
  # This class responsible for assigning
  # proper pending build to runner on runner API request
  class RegisterJobService
    include ::Gitlab::Ci::Artifacts::Logger

    attr_reader :runner, :runner_manager, :metrics

    TEMPORARY_LOCK_TIMEOUT = 3.seconds

    Result = Struct.new(:build, :build_json, :build_presented, :valid?)

    class ResultFactory
      # Returns a successful result with a build assigned to the runner.
      # This stops the queue processing loop and returns the build to the runner.
      def self.success(build, build_json, build_presented)
        Result.new(build: build, build_json: build_json, build_presented: build_presented, valid?: true)
      end

      # Returns a conflict result without a build.
      # When returned from process_build:
      # - Continues the queue processing loop to try the next build
      # - Marks the queue as invalid (valid: false) if there was a conflict
      # - If all builds are exhausted, returns HTTP 409 Conflict to the runner
      def self.conflict(valid:)
        Result.new(build: nil, build_json: nil, build_presented: nil, valid?: valid)
      end

      # Returns an invalid result (conflict with valid: false).
      # Use this when a build cannot be assigned due to a conflict (e.g., StaleObjectError,
      # InvalidTransition) to signal that the runner should retry the request.
      # The loop continues to try other builds, but if all builds fail, returns HTTP 409.
      def self.invalid
        conflict(valid: false)
      end
    end

    ##
    # The queue depth limit number has been determined by observing 95
    # percentile of effective queue depth on gitlab.com. This is only likely to
    # affect 5% of the worst case scenarios.
    MAX_QUEUE_DEPTH = 45

    def initialize(runner, runner_manager)
      @runner = runner
      @runner_manager = runner_manager
      @metrics = ::Gitlab::Ci::Queue::Metrics.new(runner)
      @logger = ::Ci::RegisterJobService::Logger.new(runner: runner)
    end

    def execute(params = {})
      replica_caught_up =
        ::Ci::Runner.sticking.find_caught_up_replica(:runner, runner.id, use_primary_on_failure: false)

      @metrics.increment_queue_operation(:queue_attempt)

      result = process_queue_with_instrumentation(params)

      # Since we execute this query against replica it might lead to false-positive
      # We might receive the positive response: "hi, we don't have any more builds for you".
      # This might not be true. If our DB replica is not up-to date with when runner event was generated
      # we might still have some CI builds to be picked. Instead we should say to runner:
      # "Hi, we don't have any more builds now,  but not everything is right anyway, so try again".
      # Runner will retry, but again, against replica, and again will check if replication lag did catch-up.
      if !replica_caught_up && !result.build
        metrics.increment_queue_operation(:queue_replication_lag)

        ResultFactory.invalid
      else
        result
      end

    ensure
      @logger.commit
    end

    private

    def process_queue_with_instrumentation(params)
      @metrics.observe_queue_time(:process, @runner.runner_type) do
        @logger.instrument(:process_queue, once: true) do
          process_queue(params)
        end
      end
    end

    def process_queue(params)
      valid = true
      depth = 0

      each_build(params) do |build, queue_size|
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

        result = @logger.instrument(:process_build) do
          process_build(build, params, queue_size: queue_size, queue_depth: depth)
        end
        next unless result

        if result.valid?
          track_success(result, depth)

          return result # rubocop:disable Cop/AvoidReturnFromBlocks
        else
          # The usage of valid: is described in
          # handling of ActiveRecord::StaleObjectError
          valid = false
        end
      end

      track_conflict(depth, valid)

      ResultFactory.conflict(valid: valid)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def each_build(params, &blk)
      queue = Ci::Queue::BuildQueueService.new(runner)
      builds = queue.build_candidates

      build_and_partition_ids = retrieve_queue(-> { queue.execute(builds) })
      queue_size = build_and_partition_ids.size

      @metrics.observe_queue_size(-> { queue_size }, @runner.runner_type)

      build_and_partition_ids.each do |build_id, partition_id|
        yield Ci::Build.find_by!(partition_id: partition_id, id: build_id), queue_size
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def retrieve_queue(queue_query_proc)
      ##
      # We want to reset a load balancing session to discard the side
      # effects of writes that could have happened prior to this moment.
      #
      ::Gitlab::Database::LoadBalancing::SessionMap.clear_session

      @metrics.observe_queue_time(:retrieve, @runner.runner_type) do
        @logger.instrument(:retrieve_queue, once: true) do
          queue_query_proc.call
        end
      end
    end

    def process_build(build, params, queue_size:, queue_depth:)
      return remove_from_queue!(build) unless build.pending?

      if runner_matched?(build)
        @metrics.increment_queue_operation(:build_can_pick)
      else
        @metrics.increment_queue_operation(:build_not_pick)

        return
      end

      # Make sure that composite identity is propagated to `PipelineProcessWorker`
      # when the build's status change.
      ::Gitlab::Auth::Identity.link_from_job(build)

      # In case when 2 runners try to assign the same build, second runner will be declined
      # with StateMachines::InvalidTransition or StaleObjectError when doing run! or save method.
      if assign_runner_with_instrumentation!(build, params)
        present_build_with_instrumentation!(build, queue_size: queue_size, queue_depth: queue_depth)
      end
    rescue ActiveRecord::StaleObjectError
      # StaleObjectError indicates another runner is concurrently processing this build.
      # By returning ResultFactory.invalid, we:
      # 1. Continue the loop to try the next build in the queue
      # 2. Mark the queue as invalid (valid: false)
      # 3. Return HTTP 409 Conflict if all builds are exhausted, signaling the runner to retry
      #
      # This approach reduces conflicts by allowing runners to try other builds instead of
      # immediately failing, which improves build assignment throughput.
      @metrics.increment_queue_operation(:build_conflict_lock)

      ResultFactory.invalid
    rescue StateMachines::InvalidTransition
      # InvalidTransition indicates the build's state changed unexpectedly (e.g., already running).
      # Similar to StaleObjectError, we continue the loop to find another build.
      @metrics.increment_queue_operation(:build_conflict_transition)

      ResultFactory.invalid
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

    def remove_from_queue!(build)
      @metrics.increment_queue_operation(:build_not_pending)

      ##
      # If this build can not be picked because we had stale data in
      # `ci_pending_builds` table, we need to respond with 409 to retry
      # this operation.
      #
      ResultFactory.invalid if ::Ci::UpdateBuildQueueService.new.remove!(build)
    end

    def runner_matched?(build)
      @logger.instrument(:process_build_runner_matched) do
        runner.matches_build?(build)
      end
    end

    def present_build_with_instrumentation!(build, queue_size:, queue_depth:)
      @logger.instrument(:process_build_present_build) do
        present_build!(build, queue_size: queue_size, queue_depth: queue_depth)
      end
    end

    # Force variables evaluation to occur now
    def present_build!(build, queue_size:, queue_depth:)
      # We need to use the presenter here because Gitaly calls in the presenter
      # may fail, and we need to ensure the response has been generated.
      presented_build = ::Ci::BuildRunnerPresenter.new(build) # rubocop:disable CodeReuse/Presenter -- old code
      presented_build.set_queue_metrics(size: queue_size, depth: queue_depth)

      @logger.instrument(:present_build_logs) do
        log_artifacts_context(build)
        log_build_dependencies_size(presented_build)
      end

      build_json = @logger.instrument(:present_build_response_json) do
        Gitlab::Json.dump(::API::Entities::Ci::JobRequest::Response.new(presented_build))
      end

      ResultFactory.success(build, build_json, presented_build)
    end

    def log_build_dependencies_size(presented_build)
      return unless ::Feature.enabled?(:ci_build_dependencies_artifacts_logger, type: :ops)

      presented_build.all_dependencies.then do |dependencies|
        size = dependencies.sum do |build|
          build.available_artifacts? ? build.artifacts_file.size : 0
        end

        log_build_dependencies(size: size, count: dependencies.size) if size > 0
      end
    end

    def assign_runner_with_instrumentation!(build, params)
      @logger.instrument(:process_build_assign_runner) do
        assign_runner!(build, params)
      end
    end

    def assign_runner!(build, params)
      build.runner_id = runner.id
      build.runner_session_attributes = params[:session] if params[:session].present?

      failure_reason, _ = @logger.instrument(:assign_runner_failure_reason) do
        pre_assign_runner_checks.find { |_, check| check.call(build, params) }
      end

      if failure_reason
        @metrics.increment_queue_operation(:runner_pre_assign_checks_failed)

        @logger.instrument(:assign_runner_drop) do
          build.drop!(failure_reason)
        end
      else
        @metrics.increment_queue_operation(:runner_pre_assign_checks_success)

        assign_job_to_running_state(build, runner_manager)
      end

      !failure_reason
    end

    def acquire_temporary_lock(build_id)
      return true if Feature.disabled?(:ci_register_job_temporary_lock, runner, type: :ops)

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

    def track_success(result, depth)
      @metrics.register_success(result.build_presented)
      @metrics.observe_queue_depth(:found, depth)
    rescue StandardError => ex
      # We should know about any errors during tracking but we don't want them to prevent
      # reporting a result to the runner
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
        ex, **build_tracking_data(result.build)
      )
    end

    def track_conflict(depth, valid)
      @metrics.increment_queue_operation(:queue_conflict) unless valid
      @metrics.observe_queue_depth(:conflict, depth) unless valid
      @metrics.observe_queue_depth(:not_found, depth) if valid
      @metrics.register_failure
    rescue StandardError => ex
      # We should know about any errors during tracking but we don't want them to prevent
      # reporting a result to the runner
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(ex)
    end

    def track_exception_for_build(ex, build)
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(ex, **build_tracking_data(build))
    end

    def build_tracking_data(build)
      {
        build_id: build.id,
        build_name: build.name,
        build_stage: build.stage_name,
        pipeline_id: build.pipeline_id,
        project_id: build.project_id
      }
    end

    def pre_assign_runner_checks
      {
        missing_dependency_failure: ->(build, _) { !build.has_valid_build_dependencies? },
        runner_unsupported: ->(build, params) { !build.supported_runner?(params.dig(:info, :features)) },
        archived_failure: ->(build, _) { build.archived? },
        project_deleted: ->(build, _) { build.project.pending_delete? },
        builds_disabled: ->(build, _) { !build.project.builds_enabled? },
        user_blocked: ->(build, _) { build.user&.blocked? }
      }
    end

    def assign_job_to_running_state(build, runner_manager)
      @logger.instrument(:assign_runner_run) do
        build.run!
      end

      # The runner_manager join record is created immediately, since it is marked as `autosave: true` to avoid race
      # conditions when one runner manager is assigned the job, and others are competing for the same job,
      # which would cause duplicate key constraint failures.
      # By only assigning the runner manager once the job starts running, we avoid the problem.
      build.runner_manager = runner_manager if runner_manager
    end
  end
end

Ci::RegisterJobService.prepend_mod_with('Ci::RegisterJobService')
