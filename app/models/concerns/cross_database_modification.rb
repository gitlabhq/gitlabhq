# frozen_string_literal: true

module CrossDatabaseModification
  extend ActiveSupport::Concern

  class TransactionStackTrackRecord
    DEBUG_STACK = Rails.env.test? && ENV['DEBUG_GITLAB_TRANSACTION_STACK']
    LOG_FILENAME = Rails.root.join("log", "gitlab_transaction_stack.log")

    EXCLUDE_DEBUG_TRACE = %w[
      lib/gitlab/database/query_analyzer
      app/models/concerns/cross_database_modification.rb
    ].freeze

    def self.logger
      @logger ||= Logger.new(LOG_FILENAME, formatter: ->(_, _, _, msg) { Gitlab::Json.dump(msg) + "\n" })
    end

    def self.log_gitlab_transactions_stack(action: nil, example: nil)
      return unless DEBUG_STACK

      message = "gitlab_transactions_stack performing #{action}"
      message += " in example #{example}" if example

      cleaned_backtrace = Gitlab::BacktraceCleaner.clean_backtrace(caller)
        .reject { |line| EXCLUDE_DEBUG_TRACE.any? { |exclusion| line.include?(exclusion) } }
        .first(5)

      logger.warn({
        message: message,
        action: action,
        gitlab_transactions_stack: ::ApplicationRecord.gitlab_transactions_stack,
        caller: cleaned_backtrace,
        thread: Thread.current.object_id
      })
    end

    def initialize(subject, gitlab_schema)
      @subject = subject
      @gitlab_schema = gitlab_schema
      @subject.gitlab_transactions_stack.push(gitlab_schema)

      self.class.log_gitlab_transactions_stack(action: :after_push)
    end

    def done!
      unless @done
        @done = true

        self.class.log_gitlab_transactions_stack(action: :before_pop)
        @subject.gitlab_transactions_stack.pop
      end

      true
    end

    def trigger_transactional_callbacks?
      false
    end

    def before_committed!; end

    def rolledback!(force_restore_state: false, should_run_callbacks: true)
      done!
    end

    def committed!(should_run_callbacks: true)
      done!
    end
  end

  included do
    private_class_method :gitlab_schema
  end

  class_methods do
    def gitlab_transactions_stack
      Thread.current[:gitlab_transactions_stack] ||= []
    end

    def transaction(**options, &block)
      super(**options) do
        # Hook into current transaction to ensure that once
        # the `COMMIT` is executed the `gitlab_transactions_stack`
        # will be allowing to execute `after_commit_queue`
        record = TransactionStackTrackRecord.new(self, gitlab_schema)

        begin
          connection.current_transaction.add_record(record)

          yield
        ensure
          record.done!
        end
      end
    end

    def gitlab_schema
      case self.name
      when 'ActiveRecord::Base', 'ApplicationRecord'
        :gitlab_main
      when 'Gitlab::Database::SecApplicationRecord'
        :gitlab_sec
      when 'Ci::ApplicationRecord'
        :gitlab_ci
      when 'PackageMetadata::ApplicationRecord'
        :gitlab_pm
      else
        Gitlab::Database::GitlabSchema.table_schema(table_name) if table_name
      end
    end
  end
end
