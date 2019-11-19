# frozen_string_literal: true

module Gitlab
  module Cluster
    #
    # LifecycleEvents lets Rails initializers register application startup hooks
    # that are sensitive to forking. For example, to defer the creation of
    # watchdog threads. This lets us abstract away the Unix process
    # lifecycles of Unicorn, Sidekiq, Puma, Puma Cluster, etc.
    #
    # We have the following lifecycle events.
    #
    # - on_before_fork (on master process):
    #
    #     Unicorn/Puma Cluster: This will be called exactly once,
    #       on startup, before the workers are forked. This is
    #       called in the PARENT/MASTER process.
    #
    #     Sidekiq/Puma Single: This is not called.
    #
    # - on_master_start (on master process):
    #
    #     Unicorn/Puma Cluster: This will be called exactly once,
    #       on startup, before the workers are forked. This is
    #       called in the PARENT/MASTER process.
    #
    #     Sidekiq/Puma Single: This is called immediately.
    #
    # - on_before_blackout_period (on master process):
    #
    #     Unicorn/Puma Cluster: This will be called before a blackout
    #       period when performing graceful shutdown of master.
    #       This is called on `master` process.
    #
    #     Sidekiq/Puma Single: This is not called.
    #
    # - on_before_graceful_shutdown (on master process):
    #
    #     Unicorn/Puma Cluster: This will be called before a graceful
    #       shutdown  of workers starts happening, but after blackout period.
    #       This is called on `master` process.
    #
    #     Sidekiq/Puma Single: This is not called.
    #
    # - on_before_master_restart (on master process):
    #
    #     Unicorn: This will be called before a new master is spun up.
    #       This is called on forked master before `execve` to become
    #       a new masterfor Unicorn. This means that this does not really
    #       affect old master process.
    #
    #     Puma Cluster: This will be called before a new master is spun up.
    #       This is called on `master` process.
    #
    #     Sidekiq/Puma Single: This is not called.
    #
    # - on_worker_start (on worker process):
    #
    #     Unicorn/Puma Cluster: This is called in the worker process
    #       exactly once before processing requests.
    #
    #     Sidekiq/Puma Single: This is called immediately.
    #
    # Blocks will be executed in the order in which they are registered.
    #
    class LifecycleEvents
      class << self
        #
        # Hook registration methods (called from initializers)
        #
        def on_worker_start(&block)
          if in_clustered_environment?
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
          if in_clustered_environment?
            on_before_fork(&block)
          else
            on_worker_start(&block)
          end
        end

        #
        # Lifecycle integration methods (called from unicorn.rb, puma.rb, etc.)
        #
        def do_worker_start
          call(@worker_start_hooks)
        end

        def do_before_fork
          call(@before_fork_hooks)
        end

        def do_before_graceful_shutdown
          call(@master_blackout_period)

          blackout_seconds = ::Settings.shutdown.blackout_seconds.to_i
          sleep(blackout_seconds) if blackout_seconds > 0

          call(@master_graceful_shutdown)
        end

        def do_before_master_restart
          call(@master_restart_hooks)
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

        def call(hooks)
          hooks&.each(&:call)
        end

        def in_clustered_environment?
          # Sidekiq doesn't fork
          return false if Sidekiq.server?

          # Unicorn always forks
          return true if defined?(::Unicorn)

          # Puma sometimes forks
          return true if in_clustered_puma?

          # Default assumption is that we don't fork
          false
        end

        def in_clustered_puma?
          return false unless defined?(::Puma)

          @puma_options && @puma_options[:workers] && @puma_options[:workers] > 0
        end
      end
    end
  end
end
