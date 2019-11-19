# frozen_string_literal: true

module Gitlab
  class Daemon
    def self.initialize_instance(*args)
      raise "#{name} singleton instance already initialized" if @instance

      @instance = new(*args)
      Kernel.at_exit(&@instance.method(:stop))
      @instance
    end

    def self.instance(*args)
      @instance ||= initialize_instance(*args)
    end

    attr_reader :thread

    def thread?
      !thread.nil?
    end

    def initialize
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
