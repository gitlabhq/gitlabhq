# frozen_string_literal: true

require 'gitlab/utils/all' # Gitlab::Utils

module Gitlab
  module Cluster
    # We take advantage of the fact that the application is pre-loaded in the primary
    # process. If it's a pre-fork server like Puma, this will be the Puma master process.
    # Otherwise it is the worker itself such as for Sidekiq.
    PRIMARY_PID = $$

    #
    # LifecycleEvents lets Rails initializers register application startup hooks
    # that are sensitive to forking. For example, to defer the creation of
    # watchdog threads. This lets us abstract away the Unix process
    # lifecycles of Sidekiq, Puma, Puma Cluster, etc.
    #
    # We have the following lifecycle events.
    #
    # - on_before_fork (on master process):
    #
    #     Puma Cluster: This will be called exactly once,
    #       on startup, before the workers are forked. This is
    #       called in the PARENT/MASTER process.
    #
    #     Sidekiq/Puma Single: This is not called.
    #
    # - on_master_start (on master process):
    #
    #     Puma Cluster: This will be called exactly once,
    #       on startup, before the workers are forked. This is
    #       called in the PARENT/MASTER process.
    #
    #     Sidekiq/Puma Single: This is called immediately.
    #
    # - on_before_blackout_period (on master process):
    #
    #     Puma Cluster: This will be called before a blackout
    #       period when performing graceful shutdown of master.
    #       This is called on `master` process.
    #
    #     Sidekiq/Puma Single: This is not called.
    #
    # - on_before_graceful_shutdown (on master process):
    #
    #     Puma Cluster: This will be called before a graceful
    #       shutdown  of workers starts happening, but after blackout period.
    #       This is called on `master` process.
    #
    #     Sidekiq/Puma Single: This is not called.
    #
    # - on_before_master_restart (on master process):
    #
    #     Puma Cluster: This will be called before a new master is spun up.
    #       This is called on `master` process.
    #
    #     Sidekiq/Puma Single: This is not called.
    #
    # - on_worker_start (on worker process):
    #
    #     Puma Cluster: This is called in the worker process
    #       exactly once before processing requests.
    #
    #     Sidekiq/Puma Single: This is called immediately.
    #
    # - on_worker_stop (on worker process):
    #
    #     Puma Cluster: Called in the worker process
    #       exactly once after it stops processing requests
    #       but before it shuts down.
    #
    #     Sidekiq: Called after the scheduler shuts down but
    #       before the worker finishes ongoing jobs.
    #
    # Blocks will be executed in the order in which they are registered.
    #
    class LifecycleEvents
      FatalError = Class.new(Exception) # rubocop:disable Lint/InheritException

      USE_FATAL_LIFECYCLE_EVENTS = Gitlab::Utils.to_boolean(ENV.fetch('GITLAB_FATAL_LIFECYCLE_EVENTS', 'true'))

      class << self
        #
        # Hook registration methods (called from initializers)
        #
        def on_worker_start(&block)
          if in_clustered_puma?
            # Defer block execution
            (@worker_start_hooks ||= []) << block
          else
            yield
          end
        end

        def on_before_fork(&block)
          # Defer block execution
          (@before_fork_hooks ||= []) << block
        end

        # Read the config/initializers/cluster_events_before_phased_restart.rb
        def on_before_blackout_period(&block)
          # Defer block execution
          (@master_blackout_period ||= []) << block
        end

        # Read the config/initializers/cluster_events_before_phased_restart.rb
        def on_before_graceful_shutdown(&block)
          # Defer block execution
          (@master_graceful_shutdown ||= []) << block
        end

        def on_before_master_restart(&block)
          # Defer block execution
          (@master_restart_hooks ||= []) << block
        end

        def on_master_start(&block)
          if in_clustered_puma?
            on_before_fork(&block)
          else
            on_worker_start(&block)
          end
        end

        def on_worker_stop(&block)
          (@worker_stop_hooks ||= []) << block
        end

        #
        # Lifecycle integration methods (called from puma.rb, etc.)
        #
        def do_worker_start
          call(:worker_start_hooks, @worker_start_hooks)
        end

        def do_before_fork
          call(:before_fork_hooks, @before_fork_hooks)
        end

        def do_before_graceful_shutdown
          call(:master_blackout_period, @master_blackout_period)

          blackout_seconds = ::Settings.shutdown.blackout_seconds.to_i
          sleep(blackout_seconds) if blackout_seconds > 0

          call(:master_graceful_shutdown, @master_graceful_shutdown)
        end

        def do_before_master_restart
          call(:master_restart_hooks, @master_restart_hooks)
        end

        def do_worker_stop
          call(:worker_stop_hooks, @worker_stop_hooks)
        end

        # DEPRECATED
        alias_method :do_master_restart, :do_before_master_restart

        # Puma doesn't use singletons (which is good) but
        # this means we need to pass through whether the
        # puma server is running in single mode or cluster mode
        def set_puma_options(options)
          @puma_options = options
        end

        private

        def call(name, hooks)
          return unless hooks

          hooks.each do |hook|
            hook.call
          rescue StandardError => e
            Gitlab::ErrorTracking.track_exception(e, type: 'LifecycleEvents', hook: hook)
            warn("ERROR: The hook #{name} failed with exception (#{e.class}) \"#{e.message}\".")

            # we consider lifecycle hooks to be fatal errors
            raise FatalError, e if USE_FATAL_LIFECYCLE_EVENTS
          end
        end

        def in_clustered_puma?
          Gitlab::Runtime.puma? && @puma_options && @puma_options[:workers] && @puma_options[:workers] > 0
        end
      end
    end
  end
end
