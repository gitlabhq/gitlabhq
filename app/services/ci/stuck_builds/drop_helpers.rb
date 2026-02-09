# frozen_string_literal: true

module Ci
  module StuckBuilds
    module DropHelpers
      BATCH_SIZE = 100

      def drop(builds, failure_reason:)
        fetch(builds) do |build|
          drop_build :outdated, build, failure_reason
        end
      end

      def drop_incomplete(builds, failure_reason:)
        fetch(builds) do |build|
          drop_incomplete_build :outdated, build, failure_reason
        end
      end

      def drop_stuck(builds, failure_reason:)
        fetch(builds) do |build|
          break unless build.stuck?

          drop_build :stuck, build, failure_reason
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def fetch(builds)
        loop do
          jobs = builds.includes(:tags, :runner, project: [:namespace, :route])
            .limit(BATCH_SIZE)
            .to_a

          break if jobs.empty?

          jobs.each do |job|
            Gitlab::ApplicationContext.with_context(project: job.project) { yield(job) }
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def drop_build(type, build, reason)
        log_dropping_message(type, build, reason)
        Gitlab::OptimisticLocking.retry_lock(build, 3, name: 'stuck_ci_jobs_worker_drop_build') do |b|
          b.drop!(reason)
        end
      rescue StandardError => ex
        build.doom!

        track_exception_for_build(ex, build)
      end

      def drop_incomplete_build(type, build, reason)
        log_dropping_message(type, build, reason)
        Gitlab::OptimisticLocking.retry_lock(build, 3, name: 'stuck_ci_jobs_worker_drop_build') do |b|
          # retry_lock resets the build on retry. Builds only lock on status, so
          # if we retry then the status has changed. This saves us a rescue +
          # query below.
          b.drop!(reason) unless b.complete?
        end
      rescue StandardError => ex
        # If this causes many race conditions we will need a common lock of
        # build status updates and this method.
        # Errors are expected when jobs complete during timeout processing.
        # Only track exceptions for incomplete builds as those are unexpected.
        unless build.reset.complete?
          track_exception_for_build(ex, build)
          build.doom!
        end
      end

      def track_exception_for_build(ex, build)
        Gitlab::ErrorTracking.track_exception(
          ex,
          build_id: build.id,
          build_name: build.name,
          build_stage: build.stage_name,
          pipeline_id: build.pipeline_id,
          project_id: build.project_id
        )
      end

      def log_dropping_message(type, build, reason)
        Gitlab::AppLogger.info(
          class: self.class.name,
          message: "Dropping #{type} build",
          build_stuck_type: type,
          build_id: build.id,
          runner_id: build.runner_id,
          build_status: build.status,
          build_failure_reason: reason
        )
      end
    end
  end
end
