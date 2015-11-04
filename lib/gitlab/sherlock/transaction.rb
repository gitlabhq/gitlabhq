module Gitlab
  module Sherlock
    class Transaction
      attr_reader :id, :type, :path, :queries, :file_samples, :started_at,
        :finished_at

      def initialize(type, path)
        @id = SecureRandom.uuid
        @type = type
        @path = path
        @duration = 0
        @queries = []
        @file_samples = []
        @started_at = nil
        @finished_at = nil
        @thread = Thread.current
      end

      def run
        @started_at = Time.now

        subscriber = subscribe_to_active_record

        retval = profile_lines { yield }

        @finished_at = Time.now

        ActiveSupport::Notifications.unsubscribe(subscriber)

        retval
      end

      def duration
        @started_at && @finished_at ? @finished_at - @started_at : 0
      end

      def to_param
        @id
      end

      def sorted_queries
        @queries.sort { |a, b| b.duration <=> a.duration }
      end

      def sorted_file_samples
        @file_samples.sort { |a, b| b.duration <=> a.duration }
      end

      def find_query(id)
        @queries.find { |query| query.id == id }
      end

      def find_file_sample(id)
        @file_samples.find { |sample| sample.id == id }
      end

      def track_query(query, bindings, start, finish)
        @queries << Query.new_with_bindings(query, bindings, start, finish)
      end

      def profile_lines
        retval = nil

        if Sherlock.enable_line_profiler?
          retval, @file_samples = LineProfiler.new.profile { yield }
        else
          retval = yield
        end

        retval
      end

      def subscribe_to_active_record
        ActiveSupport::Notifications.subscribe('sql.active_record') do |_, start, finish, _, data|
          # In case somebody uses a multi-threaded server locally (e.g. Puma) we
          # _only_ want to track queries that originate from the transaction
          # thread.
          next unless Thread.current == @thread

          track_query(data[:sql].strip, data[:binds], start, finish)
        end
      end
    end
  end
end
