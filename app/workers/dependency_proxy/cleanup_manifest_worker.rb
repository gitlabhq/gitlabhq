# frozen_string_literal: true

module DependencyProxy
  class CleanupManifestWorker
    include ApplicationWorker
    include LimitedCapacity::Worker
    include Gitlab::Utils::StrongMemoize
    include DependencyProxy::CleanupWorker

    data_consistency :always

    sidekiq_options retry: 3

    queue_namespace :dependency_proxy_manifest
    feature_category :dependency_proxy
    urgency :low
    worker_resource_boundary :unknown
    idempotent!

    private

    def model
      DependencyProxy::Manifest
    end

    def log_metadata(manifest)
      log_extra_metadata_on_done(:dependency_proxy_manifest_id, manifest.id)
      log_extra_metadata_on_done(:group_id, manifest.group_id)
    end

    def log_cleanup_item(manifest)
      logger.info(
        structured_payload(
          group_id: manifest.group_id,
          dependency_proxy_manifest_id: manifest.id
        )
      )
    end
  end
end
