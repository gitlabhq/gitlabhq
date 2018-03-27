module Gitlab
  module Sherlock
    class Transaction
      attr_reader :id, :type, :path, :queries, :file_samples, :started_at,
        :finished_at, :view_counts

      # type - The type of transaction (e.g. "GET", "POST", etc)
      # path - The path of the transaction (e.g. the HTTP request path)
      def initialize(type, path)
        @id = SecureRandom.uuid
        @type = type
        @path = path
        @queries = []
        @file_samples = []
        @started_at = nil
        @finished_at = nil
        @thread = Thread.current
        @view_counts = Hash.new(0)
      end

      # Runs the transaction and returns the block's return value.
      def run
        @started_at = Time.now

        retval = with_subscriptions do
          profile_lines { yield }
        end

        @finished_at = Time.now

        retval
      end

      # Returns the duration in seconds.
      def duration
        @duration ||= started_at && finished_at ? finished_at - started_at : 0
      end

      # Returns the total query duration in seconds.
      def query_duration
        @query_duration ||= @queries.map { |q| q.duration }.inject(:+) / 1000.0
      end

      def to_param
        @id
      end

      # Returns the queries sorted in descending order by their durations.
      def sorted_queries
        @queries.sort { |a, b| b.duration <=> a.duration }
      end

      # Returns the file samples sorted in descending order by their durations.
      def sorted_file_samples
        @file_samples.sort { |a, b| b.duration <=> a.duration }
      end

      # Finds a query by the given ID.
      #
      # id - The query ID as a String.
      #
      # Returns a Query object if one could be found, nil otherwise.
      def find_query(id)
        @queries.find { |query| query.id == id }
      end

      # Finds a file sample by the given ID.
      #
      # id - The query ID as a String.
      #
      # Returns a FileSample object if one could be found, nil otherwise.
      def find_file_sample(id)
        @file_samples.find { |sample| sample.id == id }
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
          next unless same_thread?

          unless data.fetch(:cached, data[:name] == 'CACHE')
            track_query(data[:sql].strip, data[:binds], start, finish)
          end
        end
      end

      def subscribe_to_action_view
        regex = /render_(template|partial)\.action_view/

        ActiveSupport::Notifications.subscribe(regex) do |_, start, finish, _, data|
          next unless same_thread?

          track_view(data[:identifier])
        end
      end

      private

      def track_query(query, bindings, start, finish)
        @queries << Query.new_with_bindings(query, bindings, start, finish)
      end

      def track_view(path)
        @view_counts[path] += 1
      end

      def with_subscriptions
        ar_subscriber = subscribe_to_active_record
        av_subscriber = subscribe_to_action_view

        retval = yield

        ActiveSupport::Notifications.unsubscribe(ar_subscriber)
        ActiveSupport::Notifications.unsubscribe(av_subscriber)

        retval
      end

      # In case somebody uses a multi-threaded server locally (e.g. Puma) we
      # _only_ want to track notifications that originate from the transaction
      # thread.
      def same_thread?
        Thread.current == @thread
      end
    end
  end
end
