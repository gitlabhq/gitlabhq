# frozen_string_literal: true

module Gitlab
  module Cluster
    #
    # LifecycleEvents lets Rails initializers register application startup hooks
    # that are sensitive to forking. For example, to defer the creation of
    # watchdog threads. This lets us abstract away the Unix process
    # lifecycles of Unicorn, Sidekiq, Puma, Puma Cluster, etc.
    #
    # We have three lifecycle events.
    #
    # - before_fork (only in forking processes)
    #     In forking processes (Unicorn and Puma in multiprocess mode) this
    #     will be called exactly once, on startup, before the workers are
    #     forked. This will be called in the parent process.
    # - worker_start
    # - before_master_restart (only in forking processes)
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
          return unless in_clustered_environment?

          # Defer block execution
          (@before_fork_hooks ||= []) << block
        end

        def on_master_restart(&block)
          return unless in_clustered_environment?

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
          @worker_start_hooks&.each do |block|
            block.call
          end
        end

        def do_before_fork
          @before_fork_hooks&.each do |block|
            block.call
          end
        end

        def do_master_restart
          @master_restart_hooks && @master_restart_hooks.each do |block|
            block.call
          end
        end

        # Puma doesn't use singletons (which is good) but
        # this means we need to pass through whether the
        # puma server is running in single mode or cluster mode
        def set_puma_options(options)
          @puma_options = options
        end

        private

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
