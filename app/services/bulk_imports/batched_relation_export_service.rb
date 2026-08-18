# frozen_string_literal: true

module BulkImports
  class BatchedRelationExportService
    include Gitlab::Utils::StrongMemoize

    BATCH_CACHE_KEY = 'bulk_imports/batched_relation_export/%{export_id}/%{batch_id}'
    BATCH_SIZE_CACHE_KEY = 'bulk_imports/batched_relation_export/%{export_id}/batch_size'
    CACHE_DURATION = 4.hours

    def self.cache_key(export_id, batch_id)
      Kernel.format(BATCH_CACHE_KEY, export_id: export_id, batch_id: batch_id)
    end

    def self.batch_size_cache_key(export_id)
      Kernel.format(BATCH_SIZE_CACHE_KEY, export_id: export_id)
    end

    def initialize(user, portable, relation, jid, offline_export_id: nil)
      @user = user
      @portable = portable
      @relation = relation
      @resolved_relation = portable.public_send(relation) # rubocop:disable GitlabSecurity/PublicSend
      @jid = jid
      @offline_export_id = offline_export_id
      @config = FileTransfer.config_for(portable)
    end

    def execute
      return finish_export! unless resolved_relation.exists?

      log_export_restart if export.started? && export.batches.in_progress.present?

      start_export!
      export.batches.destroy_all # rubocop: disable Cop/DestroyAll
      exported_count = enqueue_batch_exports

      # Record the totals that were actually enqueued. For the commit notes path, corrects the upfront
      # count which includes notes on commits no longer reachable from the repository (which the CommitNotesBatcher
      # does not export).
      export.update!(total_objects_count: exported_count, batches_count: export.batches.count)

      FinishBatchedRelationExportWorker.perform_async(export.id)
    end

    private

    attr_reader :user, :portable, :relation, :jid, :config, :resolved_relation, :offline_export_id

    # Returns the batch size for processing relation exports.
    #
    # The batch size determines how many records are processed together in each batch
    # during the export operation. We cache the batch size so that any retried workers
    # for the same relation export use the same batch size.
    #
    # @return [Integer] The number of records to process per batch
    def batch_size
      key = self.class.batch_size_cache_key(export.id)

      Gitlab::Cache::Import::Caching.read_integer(key) ||
        Gitlab::Cache::Import::Caching.write(
          key,
          Gitlab::CurrentSettings.relation_export_batch_size,
          timeout: CACHE_DURATION
        )
    end
    strong_memoize_attr :batch_size

    def export
      # rubocop:disable Performance/ActiveRecordSubtransactionMethods -- This is only executed from within a worker
      export_params = { offline_export_id: offline_export_id, relation: relation }
      export_params[:user] = user unless offline_export_id

      @export ||= portable.bulk_import_exports.safe_find_or_create_by!(export_params)
      # rubocop:enable Performance/ActiveRecordSubtransactionMethods
    end

    def start_export!
      update_export!('start')
    end

    def finish_export!
      # Reached only when the relation is empty, so the totals are zero. Setting them explicitly
      # avoids a count query and resets any stale totals from a previous export attempt.
      update_export!('finish', total_objects_count: 0, batches_count: 0)
    end

    def update_export!(event, total_objects_count: nil, batches_count: nil)
      attributes = {
        status_event: event,
        batched: true,
        jid: jid,
        error: nil
      }

      # total_objects_count and batches_count are NOT NULL columns, so only assign them when a
      # value is given. The real totals are set after the batches are enqueued in #execute.
      attributes[:total_objects_count] = total_objects_count unless total_objects_count.nil?
      attributes[:batches_count] = batches_count unless batches_count.nil?

      export.update!(attributes)
    end

    def enqueue_batch_exports
      perform_enqueue
    rescue ActiveRecord::QueryCanceled => e # rubocop:disable Database/RescueQueryCanceled -- notes-table pagination timed out; fall back to the repository walk
      raise e unless export_commit_notes_via_repo?

      log_fallback(e)
      reset_enqueued_batches!
      @fallback_to_repository = true

      perform_enqueue
    end

    # rubocop:disable CodeReuse/ActiveRecord -- Export orchestration pages through relations and persists batch records directly
    def perform_enqueue
      batch_number = 0
      exported_count = 0
      batch_ids = []

      each_export_batch do |ids|
        batch_number += 1
        exported_count += ids.size
        batch_id = find_or_create_batch(batch_number).id

        Gitlab::Cache::Import::Caching.set_add(self.class.cache_key(export.id, batch_id), ids, timeout: CACHE_DURATION)

        batch_ids << batch_id
      end

      batch_ids.each { |batch_id| RelationBatchExportWorker.perform_async(user.id, batch_id) }

      exported_count
    end

    def each_export_batch(&block)
      if @fallback_to_repository
        ::Import::Export::Project::CommitNotesBatcher
          .new(portable, batch_size: commit_notes_batch_size)
          .each_commit_note_id_batch(&block)
      else
        resolved_relation.in_batches(of: batch_size) do |batch| # rubocop:disable Cop/InBatches -- Generic export pages arbitrary relations; each_batch needs a typed model with EachBatch
          yield batch.pluck(batch.model.primary_key)
        end
      end
    end

    # Discards the batches (and their cached IDs) created before the pagination
    # timed out, so the repository-walk retry starts from a clean slate. No
    # workers were scheduled for them yet, since #perform_enqueue only enqueues
    # after every batch has been created.
    def reset_enqueued_batches!
      cache_keys = export.batches.pluck(:id).map { |batch_id| self.class.cache_key(export.id, batch_id) }
      Gitlab::Cache::Import::Caching.del_multiple(cache_keys)

      export.batches.destroy_all # rubocop: disable Cop/DestroyAll -- delete_all would nullify export_id (NOT NULL) instead of deleting rows, since the association has no `dependent:` option
    end

    def export_commit_notes_via_repo?
      config.commit_notes_export_via_git?(relation.to_s)
    end

    # Commit notes are small, so allow larger batches than the conservative
    # `Gitlab::CurrentSettings.relation_export_batch_size` setting used for
    # heavier relations. Still honor a larger configured
    # `relation_export_batch_size` if set.
    def commit_notes_batch_size
      [batch_size, ::Import::Export::Project::CommitNotesBatcher::DEFAULT_BATCH_SIZE].max
    end

    def find_or_create_batch(batch_number)
      export.batches.find_or_create_by!(batch_number: batch_number)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def log_export_restart
      Gitlab::Export::Logger.warn(
        message: 'Restarting batched export relation and deleting existing export batches',
        relation: relation,
        export_id: export.id,
        importer: export.import_source
      )
    end

    def log_fallback(error)
      Gitlab::Export::Logger.warn(
        message: 'commit_notes export via notes-table pagination timed out, falling back to git repository walk',
        relation: relation,
        export_id: export.id,
        Labkit::Fields::ERROR_MESSAGE => error.message
      )
    end
  end
end
