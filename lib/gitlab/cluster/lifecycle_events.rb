# frozen_string_literal: true

module Gitlab
  module Cluster
    # This class abstracts various lifecycle events for different runtime environments
    # This allows handlers for various events to be registered and executed regardless
    # of the environment. Possible environments considered while building this class
    # include Unicorn, Puma Single, Puma Clustered, Sidekiq Multithreaded Process, Ruby,
    # Rake, rails-console etc
    #
    # Blocks will be executed in the order in which they are registered.
    class LifecycleEvents
      # Initialization lifecycle event. Any block registered can expect to be
      # executed once per process. In the event of single process environments,
      # the block is executed immediately
      def self.on_worker_start(&block)
        if in_clustered_worker?
          (@worker_start_listeners ||= []) << block
        else
          block.call
        end
      end

      # Lifecycle event in the master process to signal that a child is about to be
      # forked
      def self.on_before_fork(&block)
        (@before_fork_listeners ||= []) << block
      end

      # Lifecycle event for main process restart. Signals that the main process should
      # restart.
      def self.on_master_restart(&block)
        (@master_restart_listeners ||= []) << block
      end

      # Signal worker_start event
      # This should be called from unicorn/puma/etc lifecycle hooks
      def self.signal_worker_start
        @worker_start_listeners && @worker_start_listeners.each do |block|
          block.call
        end
      end

      # Signal before_fork event
      # This should be called from unicorn/puma/etc lifecycle hooks
      def self.signal_before_fork
        @before_fork_listeners && @before_fork_listeners.each do |block|
          block.call
        end
      end

      # Signal master_restart event
      # This should be called from unicorn/puma/etc lifecycle hooks
      def self.signal_master_restart
        @master_restart_listeners && @master_restart_listeners.each do |block|
          block.call
        end
      end

      # Returns true for environments which fork worker processes,
      # noteably Puma in cluster mode and unicorn
      def self.in_clustered_worker?
        # Sidekiq doesn't fork
        return false if Sidekiq.server?

        # Unicorn always forks
        return true if defined?(::Unicorn)

        # Puma sometimes forks
        return true if in_clustered_puma?

        # Default assumption is that we don't fork
        false
      end
      private_class_method :in_clustered_worker?

      # Returns true when running in Puma in clustered mode
      def self.in_clustered_puma?
        return false unless defined?(::Puma)

        @puma_options && @puma_options[:workers] && @puma_options[:workers] > 0
      end
      private_class_method :in_clustered_puma?

      # Puma doesn't use singletons (which is good) but
      # this means we need to pass through whether the
      # puma server is running in single mode or cluster mode
      def self.set_puma_options(options)
        @puma_options = options
      end
    end
  end
end
