# frozen_string_literal: true

class BulkImportWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  feature_category :importers
  tags :exclude_from_kubernetes

  sidekiq_options retry: false, dead: false

  PERFORM_DELAY = 5.seconds
  DEFAULT_BATCH_SIZE = 5

  def perform(bulk_import_id)
    @bulk_import = BulkImport.find_by_id(bulk_import_id)

    return unless @bulk_import
    return if @bulk_import.finished? || @bulk_import.failed?
    return @bulk_import.fail_op! if all_entities_failed?
    return @bulk_import.finish! if all_entities_processed? && @bulk_import.started?
    return re_enqueue if max_batch_size_exceeded? # Do not start more jobs if max allowed are already running

    @bulk_import.start! if @bulk_import.created?

    created_entities.first(next_batch_size).each do |entity|
      create_pipeline_tracker_for(entity)

      BulkImports::ExportRequestWorker.perform_async(entity.id)
      BulkImports::EntityWorker.perform_async(entity.id)

      entity.start!
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

  def started_entities
    entities.with_status(:started)
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

  def max_batch_size_exceeded?
    started_entities.count >= DEFAULT_BATCH_SIZE
  end

  def next_batch_size
    [DEFAULT_BATCH_SIZE - started_entities.count, 0].max
  end

  # A new BulkImportWorker job is enqueued to either
  #   - Process the new BulkImports::Entity created during import (e.g. for the subgroups)
  #   - Or to mark the `bulk_import` as finished
  def re_enqueue
    BulkImportWorker.perform_in(PERFORM_DELAY, @bulk_import.id)
  end

  def create_pipeline_tracker_for(entity)
    BulkImports::Stage.pipelines.each do |stage, pipeline|
      entity.trackers.create!(
        stage: stage,
        pipeline_name: pipeline
      )
    end
  end
end
