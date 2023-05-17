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
    rescue StandardError => e
      fail_export!(e)
    ensure
      FinishBatchedRelationExportWorker.perform_async(export.id)
    end

    private

    attr_reader :user, :portable, :relation, :jid, :config, :resolved_relation

    def export
      @export ||= portable.bulk_import_exports.find_or_create_by!(relation: relation) # rubocop:disable CodeReuse/ActiveRecord
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

    def enqueue_batch_exports
      resolved_relation.each_batch(of: BATCH_SIZE) do |batch, batch_number|
        batch_id = find_or_create_batch(batch_number).id
        ids = batch.pluck(batch.model.primary_key) # rubocop:disable CodeReuse/ActiveRecord

        Gitlab::Cache::Import::Caching.set_add(self.class.cache_key(export.id, batch_id), ids, timeout: CACHE_DURATION)

        RelationBatchExportWorker.perform_async(user.id, batch_id)
      end
    end

    def find_or_create_batch(batch_number)
      export.batches.find_or_create_by!(batch_number: batch_number) # rubocop:disable CodeReuse/ActiveRecord
    end

    def fail_export!(exception)
      Gitlab::ErrorTracking.track_exception(exception, portable_id: portable.id, portable_type: portable.class.name)

      export.update!(status_event: 'fail_op', error: exception.message.truncate(255))
    end
  end
end
