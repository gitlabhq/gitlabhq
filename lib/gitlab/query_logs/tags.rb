# frozen_string_literal: true

# Custom tag definitions for ActiveRecord::QueryLogs.
# These tags are appended to SQL queries as comments to aid in tracing
# queries back to their application context.
#
# Each tag is defined as a callable (lambda) that receives the Rails
# execution context hash. The connection is available via context[:connection].
#
# See config/initializers/query_logs.rb for the full configuration.
module Gitlab
  module QueryLogs
    module Tags
      # Pre-compiled regexp of call-stack frames to ignore when computing the
      # :line tag for SQL queries. Mirrors the list that the old
      # marginalia :line component used so the performance profile is the same:
      # a single Regexp#match? per frame rather than running the full
      # ActiveSupport::BacktraceCleaner pipeline (filters + multiple silencer
      # lambdas), which is ~40x slower.
      LINES_TO_IGNORE = Regexp.union(
        Gitlab::BacktraceCleaner::IGNORE_BACKTRACES + %w[
          lib/ruby/gems/
          lib/gem_extensions/
          lib/ruby/
          lib/gitlab/query_logs
          gems/
          lib/gitlab/database/load_balancing/connection_proxy.rb
          app/models/concerns/use_sql_function_for_primary_key_lookups.rb
        ]
      ).freeze

      # Returns the current correlation ID from Labkit, or from the Sidekiq
      # job context when running inside a worker.
      def self.correlation_id(context)
        job = sidekiq_job(context)

        if job
          job["correlation_id"]
        else
          Labkit::Correlation::CorrelationId.current_id
        end
      end

      # Returns the Sidekiq job ID (jid). Only set when running inside a worker.
      def self.jid(context)
        job = sidekiq_job(context)
        return unless job

        job["jid"]
      end

      # Returns the caller ID from the Labkit context (e.g. controller#action or
      # worker class name). Used as the endpoint_id tag.
      def self.endpoint_id(_context)
        Labkit::Context.current&.get_attribute(:caller_id)
      end

      # Returns the database config name for the connection used in the query
      # (e.g. "main", "ci", "main_replica").
      def self.db_config_name(context)
        connection = context[:connection]
        return unless connection

        ::Gitlab::Database.db_config_name(connection)
      end

      # Returns the database name for the connection used in the query
      # (e.g. "gitlabhq_production", "gitlabhq_production_ci").
      def self.db_config_database(context)
        connection = context[:connection]
        return unless connection

        ::Gitlab::Database.db_config_database(connection)
      end

      # Returns the hostname of the machine running a Rails console session.
      # Only set when running inside a console.
      def self.console_hostname(_context)
        return unless ::Gitlab::Runtime.console?

        @cached_console_hostname ||= Socket.gethostname
      end

      # Returns the username of the person running a Rails console session.
      # Only set when running inside a console.
      def self.console_username(_context)
        return unless ::Gitlab::Runtime.console?

        ENV['SUDO_USER'] || ENV['USER']
      end

      # Returns the location that issued the current SQL query as a string in the
      # format "/path/to/file.rb:12:in `method'", relative to the application
      # root, skipping internal/gem frames.
      #
      # Uses LINES_TO_IGNORE (a single pre-compiled Regexp) rather
      # than ActiveRecord::QueryLogs.query_source_location, which runs the full
      # BacktraceCleaner pipeline (multiple lambdas + filters per frame, ~40x
      # slower) and causes severe slowdowns in specs that run Sidekiq inline.
      #
      # Thread.each_caller_location does not return an Enumerator without a block,
      # so `return` is the only way to short-circuit it - matching the upstream
      # Rails implementation of query_source_location.
      def self.line(_context)
        if Thread.respond_to?(:each_caller_location)
          Thread.each_caller_location do |location|
            frame = location.to_s
            return relative_frame(frame) unless LINES_TO_IGNORE.match?(frame) # rubocop:disable Cop/AvoidReturnFromBlocks -- see method comment above
          end
        else
          frame = caller_locations(1)
            .lazy
            .map(&:to_s)
            .find { |f| !LINES_TO_IGNORE.match?(f) }

          relative_frame(frame) if frame
        end
      end

      # Call stack frames are absolute paths. Strip the application root so that
      # the annotation stays readable and short, as the marginalia :line
      # component did.
      private_class_method def self.relative_frame(frame)
        return frame unless frame.start_with?(rails_root)

        frame[rails_root.length..]
      end

      private_class_method def self.rails_root
        @rails_root ||= Rails.root.to_s
      end

      private_class_method def self.sidekiq_job(context)
        job = context[:job]
        return unless job

        # ActionMailer::MailDeliveryJob inherits from ActiveJob::Base and is
        # not supported by the Sidekiq job context directly, so we normalise
        # it to the same hash shape used for regular Sidekiq workers.
        if job.is_a?(ActionMailer::MailDeliveryJob)
          {
            "class" => job.arguments.first,
            "jid" => job.job_id
          }
        else
          job
        end
      end
    end
  end
end
