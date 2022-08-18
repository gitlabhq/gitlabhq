# frozen_string_literal: true

module Gitlab
  # DEPRECATED. Use Gitlab::BackgroundTask for new code instead.
  class Daemon
    # Options:
    # - recreate: We usually only allow a single instance per process to exist;
    #             this can be overridden with this switch, so that existing
    #             instances are stopped and recreated.
    def self.initialize_instance(*args, recreate: false, **options)
      if @instance
        if recreate
          @instance.stop
        else
          raise "#{name} singleton instance already initialized"
        end
      end

      @instance = new(*args, **options)
      Kernel.at_exit(&@instance.method(:stop))
      @instance
    end

    def self.instance(...)
      @instance ||= initialize_instance(...)
    end

    attr_reader :thread

    def thread?
      !thread.nil?
    end

    # Possible options:
    # - synchronous [Boolean] if true, turns `start` into a blocking call
    def initialize(**options)
      @synchronous = options[:synchronous]
      @mutex = Mutex.new
    end

    def enabled?
      true
    end

    def thread_name
      self.class.name.demodulize.underscore
    end

    def start
      return unless enabled?

      @mutex.synchronize do
        break thread if thread?

        if start_working
          @thread = Thread.new do
            Thread.current.name = thread_name
            run_thread
          end

          @thread.join if @synchronous

          @thread
        end
      end
    end

    def stop
      @mutex.synchronize do
        break unless thread?

        stop_working

        if thread
          thread.wakeup if thread.alive?
          begin
            thread.join unless Thread.current == thread
          rescue Exception # rubocop:disable Lint/RescueException
          end
          @thread = nil
        end
      end
    end

    private

    # Executed in lock context before starting thread
    # Needs to return success
    def start_working
      true
    end

    # Executed in separate thread
    def run_thread
      raise NotImplementedError
    end

    # Executed in lock context
    def stop_working
      # no-ops
    end
  end
end
