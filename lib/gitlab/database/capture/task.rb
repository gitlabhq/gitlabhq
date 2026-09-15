# frozen_string_literal: true

module Gitlab
  module Database
    # A background task that processes an in-memory queue of database queries
    module Capture
      class Task
        DATA_FORMAT_VERSION = 'v1'
        DEFAULT_CHUNK_MAX_STATEMENTS = 10_000
        DEFAULT_QUEUE_MAX_SIZE = 5_000
        DEFAULT_SLEEP_TIME_SECONDS = 1.0

        attr_reader :database_name, :client_identifier, :queue

        def initialize(database_name:)
          @database_name = database_name
          @client_identifier = format('%08x', Zlib.crc32("#{Socket.gethostname}:#{Process.pid}"))
          @chunk_number = 0
          @chunk_lsn = nil
          @statements = []
          @queue = ::Thread::SizedQueue.new(DEFAULT_QUEUE_MAX_SIZE)
          @queue_already_full = false
          Tasks[database_name] = self
        end

        def push(statement)
          @queue.push(statement, timeout: 0) || queue_full_warning
        rescue ClosedQueueError
          nil
        end

        # Closing the queue is the stop signal: producers see it through
        # ClosedQueueError in #push, and this loop sees it through its exit
        # condition. A closed queue keeps yielding buffered items, so the
        # loop drains what producers pushed before shutdown.
        def call
          Gitlab::AppLogger.info(message: 'database capture task started', **log_labels)

          until queue.closed? && queue.empty?
            begin
              item = queue.pop(timeout: DEFAULT_SLEEP_TIME_SECONDS)
              next unless item

              @statements << item

              # Read the LSN when the first statement of a chunk arrives, not
              # earlier: replay restores the target to this location before it
              # replays the chunk, so the LSN must describe the database just
              # before the chunk's first statement. An idle task never reads it.
              @chunk_lsn ||= primary_write_location

              flush_chunk if @statements.size >= chunk_max_statements
            rescue StandardError => error
              # A transient failure (e.g. primary_write_location during a
              # failover) must not kill the capture thread. Buffered statements
              # are kept for the next attempt; sleep so a persistent failure
              # does not turn the processing loop into a hot loop.
              Gitlab::ErrorTracking.track_exception(error, database_name: database_name)

              sleep(DEFAULT_SLEEP_TIME_SECONDS)
            end
          end

          # Ship whatever is still buffered. Outside the rescue deliberately:
          # a failure here propagates to Thread#join, where BackgroundTask#stop
          # tracks it.
          flush_chunk

          Gitlab::AppLogger.info(
            message: 'database capture task stopped',
            **log_labels(stop_reason: @stop_reason).compact
          )
        end

        def stop
          stop_working(reason: 'background task stopped')
        end

        def chunk_max_statements
          DEFAULT_CHUNK_MAX_STATEMENTS
        end

        private

        def flush_chunk
          return if @statements.empty?

          # Normally set when the chunk's first statement arrived; retry here
          # so a transient failure on the last pop before shutdown cannot
          # produce a chunk id with a nil LSN.
          @chunk_lsn ||= primary_write_location

          chunk_id = "#{DATA_FORMAT_VERSION}-#{database_name}-#{client_identifier}-#{@chunk_number}-#{@chunk_lsn}"

          # Logged before the upload so a chunk that fails mid-upload still
          # leaves a trace to pair with the tracked exception.
          Gitlab::AppLogger.info(
            message: 'database capture processing a chunk',
            **log_labels(
              chunk_id: chunk_id,
              statements: @statements.size
            ).compact
          )

          upload_chunk(chunk_id)

          @statements = []
          @chunk_lsn = nil
          @chunk_number += 1
          @queue_already_full = false
        end

        def primary_write_location
          Gitlab::Database.database_base_models[database_name].connection.load_balancer.primary_write_location
        end

        # A failed upload drops the chunk but must not kill the capture thread.
        def upload_chunk(chunk_id)
          filename = "#{chunk_id.tr('/', '-')}.ndjson"

          Storage.upload(filename, serialized_statements.join("\n"))
        rescue StandardError => error
          Gitlab::ErrorTracking.track_exception(error, chunk_id: chunk_id, database_name: database_name)
        end

        # A statement that cannot serialize (e.g. a binary value that slipped
        # past the analyzer's bind normalization) is dropped and tracked on
        # its own so it cannot poison the rest of the chunk.
        def serialized_statements
          @statements.filter_map do |statement|
            Gitlab::Json.dump(statement)
          rescue StandardError => error
            Gitlab::ErrorTracking.track_exception(error, database_name: database_name)
            nil
          end
        end

        def log_labels(extra = {})
          extra.merge(
            client_identifier: client_identifier,
            database_name: database_name
          )
        end

        def queue_full_warning
          return if @queue_already_full

          Gitlab::AppLogger.warn(message: 'database capture task encountered queue full', **log_labels)
          @queue_already_full = true
        end

        def stop_working(reason:)
          return if @queue.closed?

          @stop_reason = reason
          @queue.close
        end
      end
    end
  end
end
