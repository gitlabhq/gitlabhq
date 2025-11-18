# frozen_string_literal: true

module Cells
  # This class is a fake ActiveRecord::Base which implements the interface
  # partially so that it can be used with
  # ActiveRecord::ConnectionAdapters::Transaction#add_record
  # https://github.com/rails/rails/blob/v7.1.5.2/activerecord/lib/active_record/connection_adapters/abstract/transaction.rb#L147-L155
  # From there, several methods are required to be implemented:
  # * #before_committed!
  #   * Normally implemented by ActiveRecord::Transactions
  # * #committed!
  #   * Normally implemented by ActiveRecord::Transactions
  # * #rolledback!
  #   * Normally implemented by ActiveRecord::Transactions
  # * #trigger_transactional_callbacks?
  #   * Normally implemented by ActiveRecord::Transactions
  #   * Overridden by Cells::TransactionRecord to avoid more interfaces needed
  # * #destroyed?
  #   * Normally implemented by ActiveRecord::Persistence but we ignore it
  # * #_new_record_before_last_commit
  #   * Normally implemented by ActiveRecord::Transactions
  # We ignore some methods because they won't be called under specific
  # conditions, specifically when the following both return true:
  # * #trigger_transactional_callbacks?
  class TransactionRecord
    Error = Class.new(RuntimeError)

    module TransactionExtension
      attr_accessor :cells_current_transaction_record
    end

    TIMEOUT_IN_SECONDS = 0.2

    # Extend the transaction class with an accessor to store a TransactionRecord
    # in `cells_current_transaction_record`. Each transaction object is unique,
    # and Rails manages their lifecycle, so explicit cleanup isn't required.
    # Nested transactions aren't supported or expected in this design.
    def self.current_transaction(connection)
      return unless Current.cells_claims_leases?

      # The Cells::OutstandingLease requires a transaction to be open
      # to ensure that the lease is only created if the transaction
      # within a transaction and not outside of one
      if connection.current_transaction.closed?
        raise Error, 'The Cells::TransactionRecord requires transaction to be open'
      end

      current_transaction = connection.current_transaction

      instance = current_transaction.cells_current_transaction_record
      return instance if instance

      TransactionRecord.new(connection, current_transaction).tap do |instance|
        current_transaction.cells_current_transaction_record = instance
        # https://api.rubyonrails.org/v7.1.5.2/classes/ActiveRecord/ConnectionAdapters/DatabaseStatements.html#method-i-add_transaction_record
        # https://github.com/rails/rails/blob/v7.1.5.2/activerecord/lib/active_record/connection_adapters/abstract/transaction.rb#L147-L155
        current_transaction.add_record(instance)
      end
    end

    def initialize(connection, transaction)
      @connection = connection
      @transaction = transaction
      @create_records = []
      @destroy_records = []
      @outstanding_lease = nil
      @done = false
    end

    def create_record(metadata)
      raise Error, 'Lease already created' if outstanding_lease

      create_records << metadata
    end

    def destroy_record(metadata)
      raise Error, 'Lease already created' if outstanding_lease

      destroy_records << metadata
    end

    # Always trigger callbacks. See:
    # ActiveRecord::ConnectionAdapters::Transaction#
    #   prepare_instances_to_run_callbacks_on
    # https://github.com/rails/rails/blob/v7.1.5.2/activerecord/lib/active_record/connection_adapters/abstract/transaction.rb#L269
    def trigger_transactional_callbacks?
      true
    end

    def before_committed!
      raise Error, 'Already done' if done
      raise Error, 'Already created lease' if outstanding_lease
      raise Error, 'Attributes can now only be claimed on main DB' if Cells::OutstandingLease.connection != @connection

      @outstanding_lease = Cells::OutstandingLease.create_from_request!(
        create_records: create_records,
        destroy_records: destroy_records,
        deadline: deadline
      )
    end

    def rolledback!(force_restore_state: false, should_run_callbacks: true) # rubocop:disable Lint/UnusedMethodArgument -- this needs to follow the interface
      raise Error, 'Already done' if done

      # It is possible that lease might be not created yet,
      # since the transaction might be rolledback prematurely
      return unless outstanding_lease

      outstanding_lease.send_rollback_update!(deadline: deadline)
      outstanding_lease.destroy! # the lease is no longer needed
      @done = true
    end

    def committed!(should_run_callbacks: true) # rubocop:disable Lint/UnusedMethodArgument -- this needs to follow the interface
      raise Error, 'Already done' if done
      raise Error, 'No lease created' unless outstanding_lease

      outstanding_lease.send_commit_update!(deadline: deadline)
      outstanding_lease.destroy! # the lease is no longer needed
      @done = true
    end

    private

    attr_reader :create_records, :destroy_records, :done, :outstanding_lease

    def deadline
      GRPC::Core::TimeConsts.from_relative_time(TIMEOUT_IN_SECONDS)
    end
  end
end
