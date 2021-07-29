# frozen_string_literal: true

module Gitlab
  module Database
    module MultiThreadedMigration
      MULTI_THREAD_AR_CONNECTION = :thread_local_ar_connection

      # This overwrites the default connection method so that every thread can
      # use a thread-local connection, while still supporting all of Rails'
      # migration methods.
      def connection
        Thread.current[MULTI_THREAD_AR_CONNECTION] ||
          ActiveRecord::Base.connection
      end

      # Starts a thread-pool for N threads, along with N threads each using a
      # single connection. The provided block is yielded from inside each
      # thread.
      #
      # Example:
      #
      #     with_multiple_threads(4) do
      #       execute('SELECT ...')
      #     end
      #
      # thread_count - The number of threads to start.
      #
      # join - When set to true this method will join the threads, blocking the
      #        caller until all threads have finished running.
      #
      # Returns an Array containing the started threads.
      def with_multiple_threads(thread_count, join: true)
        pool = Gitlab::Database.main.create_connection_pool(thread_count)

        threads = Array.new(thread_count) do
          Thread.new do
            pool.with_connection do |connection|
              Thread.current[MULTI_THREAD_AR_CONNECTION] = connection
              yield
            ensure
              Thread.current[MULTI_THREAD_AR_CONNECTION] = nil
            end
          end
        end

        threads.each(&:join) if join

        threads
      end
    end
  end
end
