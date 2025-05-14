# frozen_string_literal: true

module Ci
  class DeleteObjectsService
    TransactionInProgressError = Class.new(StandardError)
    TRANSACTION_MESSAGE = "can't perform network calls inside a database transaction"
    BATCH_SIZE = 100
    RETRY_IN = 10.minutes
    ACCEPTABLE_DELAY = 12.hours

    def execute
      objects = load_next_batch

      destroy_everything(objects)
    end

    def remaining_batches_count(max_batch_count:)
      Ci::DeletedObject
        .ready_for_destruction(max_batch_count * BATCH_SIZE)
        .size
        .fdiv(BATCH_SIZE)
        .ceil
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def load_next_batch
      # `find_by_sql` performs a write in this case and we need to wrap it in
      # a transaction to stick to the primary database.
      Ci::DeletedObject.transaction do
        Ci::DeletedObject.find_by_sql([next_batch_sql, { new_pick_up_at: RETRY_IN.from_now }])
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def next_batch_sql
      <<~SQL.squish
      UPDATE "ci_deleted_objects"
        SET "pick_up_at" = :new_pick_up_at
        WHERE "ci_deleted_objects"."id" IN (#{locked_object_ids_sql})
        RETURNING *
      SQL
    end

    def locked_object_ids_sql
      Ci::DeletedObject.lock_for_destruction(BATCH_SIZE).to_sql
    end

    def destroy_everything(objects)
      raise TransactionInProgressError, TRANSACTION_MESSAGE if transaction_open?
      return ServiceResponse.success if objects.empty?

      deleted = []

      objects.each do |object|
        if object.delete_file_from_storage
          deleted << object
          ::Gitlab::Metrics::CiDeletedObjectProcessingSlis.record_error(error: false)
          ::Gitlab::Metrics::CiDeletedObjectProcessingSlis.record_apdex(
            success: object.created_at > ACCEPTABLE_DELAY.ago)
        else
          ::Gitlab::Metrics::CiDeletedObjectProcessingSlis.record_error(error: true)
        end
      end

      Ci::DeletedObject.id_in(deleted.map(&:id)).delete_all

      ServiceResponse.success
    end

    def transaction_open?
      Ci::DeletedObject.connection.transaction_open?
    end
  end
end
