# frozen_string_literal: true

module Packages
  module CleanupArtifactWorker
    extend ActiveSupport::Concern
    include CronjobChildWorker
    include LimitedCapacity::Worker
    include Gitlab::Utils::StrongMemoize

    def perform_work
      return unless artifact

      begin
        artifact.transaction do
          log_metadata(artifact)

          artifact.destroy!
        end
      rescue StandardError => exception
        unless artifact&.destroyed?
          artifact&.update_column(:status, :error)
        end

        Gitlab::ErrorTracking.log_exception(
          exception,
          class: self.class.name
        )
      end

      after_destroy
    end

    def remaining_work_count
      artifacts_pending_destruction.limit(max_running_jobs + 1).count
    end

    private

    def model
      raise NotImplementedError
    end

    def log_metadata
      raise NotImplementedError
    end

    def log_cleanup_item
      raise NotImplementedError
    end

    def after_destroy
      # no op
    end

    def artifact
      strong_memoize(:artifact) do
        model.transaction do
          to_delete = next_item

          if to_delete
            to_delete.update_column(:status, :processing)
            log_cleanup_item(to_delete)
          end

          to_delete
        end
      end
    end

    def artifacts_pending_destruction
      model.pending_destruction
    end

    def next_item
      model.next_pending_destruction(order_by: :updated_at)
    end
  end
end
