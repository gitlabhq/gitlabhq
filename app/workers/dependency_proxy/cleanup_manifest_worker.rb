# frozen_string_literal: true

module DependencyProxy
  class CleanupManifestWorker
    include ApplicationWorker
    include CronjobChildWorker
    include ::Packages::CleanupArtifactWorker
    include Gitlab::Utils::StrongMemoize

    data_consistency :sticky

    queue_namespace :dependency_proxy_manifest
    feature_category :virtual_registry
    urgency :low
    worker_resource_boundary :unknown
    idempotent!

    def max_running_jobs
      ::Gitlab::CurrentSettings.dependency_proxy_ttl_group_policy_worker_capacity
    end

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
