# frozen_string_literal: true

module BulkImports
  class BatchedRelationExportService
    include Gitlab::Utils::StrongMemoize

    BATCH_SIZE = 1000
    BATCH_CACHE_KEY = 'bulk_imports/batched_relation_export/%{export_id}/%{batch_id}'
    CACHE_DURATION = 4.hours

    def self.cache_key(export_id, batch_id)
      Kernel.format(BATCH_CACHE_KEY, export_id: export_id, batch_id: batch_id)
    end

    def initialize(user, portable, relation, jid)
      @user = user
      @portable = portable
      @relation = relation
      @resolved_relation = portable.public_send(relation) # rubocop:disable GitlabSecurity/PublicSend
      @jid = jid
    end

    def execute
      return finish_export! if batches_count == 0

      start_export!
      export.batches.destroy_all # rubocop: disable Cop/DestroyAll
      enqueue_batch_exports

      FinishBatchedRelationExportWorker.perform_async(export.id)
    end

    private

    attr_reader :user, :portable, :relation, :jid, :config, :resolved_relation

    def export
      # rubocop:disable Performance/ActiveRecordSubtransactionMethods -- This is only executed from within a worker
      @export ||= portable.bulk_import_exports.safe_find_or_create_by!(relation: relation, user: user)
      # rubocop:enable Performance/ActiveRecordSubtransactionMethods
    end

    def objects_count
      resolved_relation.count
    end

    def batches_count
      objects_count.fdiv(BATCH_SIZE).ceil
    end

    def start_export!
      update_export!('start')
    end

    def finish_export!
      update_export!('finish')
    end

    def update_export!(event)
      export.update!(
        status_event: event,
        total_objects_count: objects_count,
        batched: true,
        batches_count: batches_count,
        jid: jid,
        error: nil
      )
    end

    # rubocop:disable Cop/InBatches
    # rubocop:disable CodeReuse/ActiveRecord
    def enqueue_batch_exports
      batch_number = 0

      resolved_relation.in_batches(of: BATCH_SIZE) do |batch|
        batch_number += 1

        batch_id = find_or_create_batch(batch_number).id
        ids = batch.pluck(batch.model.primary_key)

        Gitlab::Cache::Import::Caching.set_add(self.class.cache_key(export.id, batch_id), ids, timeout: CACHE_DURATION)

        RelationBatchExportWorker.perform_async(user.id, batch_id)
      end
    end
    # rubocop:enable Cop/InBatches

    def find_or_create_batch(batch_number)
      export.batches.find_or_create_by!(batch_number: batch_number)
    end
    # rubocop:enable CodeReuse/ActiveRecord
  end
end
