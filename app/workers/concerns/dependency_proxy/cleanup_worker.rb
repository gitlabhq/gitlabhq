# frozen_string_literal: true

module DependencyProxy
  module CleanupWorker
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    def perform_work
      return unless artifact

      log_metadata(artifact)

      artifact.destroy!
    rescue StandardError
      artifact&.error!
    end

    def max_running_jobs
      ::Gitlab::CurrentSettings.dependency_proxy_ttl_group_policy_worker_capacity
    end

    def remaining_work_count
      expired_artifacts.limit(max_running_jobs + 1).count
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

    def artifact
      strong_memoize(:artifact) do
        model.transaction do
          to_delete = next_item

          if to_delete
            to_delete.processing!
            log_cleanup_item(to_delete)
          end

          to_delete
        end
      end
    end

    def expired_artifacts
      model.expired
    end

    def next_item
      expired_artifacts.lock_next_by(:updated_at).first
    end
  end
end
