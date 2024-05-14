# frozen_string_literal: true

module Ci
  class UpdateBuildQueueService
    InvalidQueueTransition = Class.new(StandardError)

    attr_reader :metrics

    def initialize(metrics = ::Gitlab::Ci::Queue::Metrics)
      @metrics = metrics
    end

    ##
    # Add a build to the pending builds queue
    #
    def push(build, transition)
      raise InvalidQueueTransition unless transition.to == 'pending'

      transition.within_transaction do
        result = build.create_queuing_entry!

        unless result.empty?
          metrics.increment_queue_operation(:build_queue_push)

          result.rows.dig(0, 0)
        end
      end
    end

    ##
    # Remove a build from the pending builds queue
    #
    def pop(build, transition)
      raise InvalidQueueTransition unless transition.from == 'pending'

      transition.within_transaction { remove!(build) }
    end

    ##
    # Force remove build from the queue, without checking a transition state
    #
    def remove!(build)
      removed = build.all_queuing_entries.delete_all

      if removed > 0
        metrics.increment_queue_operation(:build_queue_pop)

        build.id
      end
    end

    ##
    # Add runner build tracking entry (used for queuing and for runner fleet dashboard).
    #
    def track(build, transition)
      return if build.runner.nil?

      raise InvalidQueueTransition unless transition.to == 'running'

      transition.within_transaction do
        result = ::Ci::RunningBuild.upsert_build!(build)

        unless result.empty?
          metrics.increment_queue_operation(:shared_runner_build_new) if build.shared_runner_build?

          result.rows.dig(0, 0)
        end
      end
    end

    ##
    # Remove a runtime build tracking entry for a runner build (used for queuing and for runner fleet dashboard).
    #
    def untrack(build, transition)
      return if build.runner.nil?

      raise InvalidQueueTransition unless transition.from == 'running'

      transition.within_transaction do
        removed = build.all_runtime_metadata.delete_all

        if removed > 0
          metrics.increment_queue_operation(:shared_runner_build_done) if build.shared_runner_build?

          build.id
        end
      end
    end

    ##
    # Unblock runner associated with given project / build
    #
    def tick(build)
      tick_for(build, build.project.all_available_runners)
    end

    private

    def tick_for(build, runners)
      runners = runners.with_recent_runner_queue
      runners = runners.with_tags

      metrics.observe_active_runners(-> { runners.to_a.size })

      runners.each do |runner|
        metrics.increment_runner_tick(runner)

        runner.pick_build!(build)
      end
    end
  end
end
