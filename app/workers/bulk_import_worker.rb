# frozen_string_literal: true

class BulkImportWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  PERFORM_DELAY = 5.seconds

  data_consistency :always
  feature_category :importers
  sidekiq_options retry: false, dead: false

  def perform(bulk_import_id)
    @bulk_import = BulkImport.find_by_id(bulk_import_id)

    return unless @bulk_import
    return if @bulk_import.finished? || @bulk_import.failed?
    return @bulk_import.fail_op! if all_entities_failed?
    return @bulk_import.finish! if all_entities_processed? && @bulk_import.started?

    @bulk_import.start! if @bulk_import.created?

    created_entities.find_each do |entity|
      BulkImports::CreatePipelineTrackersService.new(entity).execute!

      entity.start!

      BulkImports::ExportRequestWorker.perform_async(entity.id)
    end

    re_enqueue
  rescue StandardError => e
    Gitlab::ErrorTracking.track_exception(e, bulk_import_id: @bulk_import&.id)

    @bulk_import&.fail_op
  end

  private

  def entities
    @entities ||= @bulk_import.entities
  end

  def created_entities
    entities.with_status(:created)
  end

  def all_entities_processed?
    entities.all? { |entity| entity.finished? || entity.failed? }
  end

  def all_entities_failed?
    entities.all? { |entity| entity.failed? }
  end

  # A new BulkImportWorker job is enqueued to either
  #   - Process the new BulkImports::Entity created during import (e.g. for the subgroups)
  #   - Or to mark the `bulk_import` as finished
  def re_enqueue
    BulkImportWorker.perform_in(PERFORM_DELAY, @bulk_import.id)
  end
end
