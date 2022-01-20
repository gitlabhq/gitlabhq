# frozen_string_literal: true

module CrossDatabaseModification
  extend ActiveSupport::Concern

  class TransactionStackTrackRecord
    def initialize(subject, gitlab_schema)
      @subject = subject
      @gitlab_schema = gitlab_schema
      @subject.gitlab_transactions_stack.push(gitlab_schema)
    end

    def done!
      unless @done
        @done = true
        @subject.gitlab_transactions_stack.pop
      end

      true
    end

    def trigger_transactional_callbacks?
      false
    end

    def before_committed!
    end

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
      if track_gitlab_schema_in_current_transaction?
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
      else
        super(**options, &block)
      end
    end

    def track_gitlab_schema_in_current_transaction?
      return false unless Feature::FlipperFeature.table_exists?

      Feature.enabled?(:track_gitlab_schema_in_current_transaction, default_enabled: :yaml)
    rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
      false
    end

    def gitlab_schema
      case self.name
      when 'ActiveRecord::Base', 'ApplicationRecord'
        :gitlab_main
      when 'Ci::ApplicationRecord'
        :gitlab_ci
      else
        Gitlab::Database::GitlabSchema.table_schema(table_name) if table_name
      end
    end
  end
end
