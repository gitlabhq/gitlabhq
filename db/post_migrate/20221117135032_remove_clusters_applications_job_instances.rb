# frozen_string_literal: true

class RemoveClustersApplicationsJobInstances < Gitlab::Database::Migration[2.0]
  DEPRECATED_JOB_CLASSES = %w[
    ClusterConfigureIstioWorker
    ClusterInstallAppWorker
    ClusterPatchAppWorker
    ClusterUpdateAppWorker
    ClusterUpgradeAppWorker
    ClusterWaitForAppInstallationWorker
    ClusterWaitForAppUpdateWorker
    ClusterWaitForIngressIpAddressWorker
  ]

  disable_ddl_transaction!

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # no-op Why: This migration removes any instances of deprecated job classes
    # from expected queues via the sidekiq_queue_length method. Once the job
    # class instances are removed, they cannot be added back. These job classes
    # are deprecated and previous MRs have already no-op'd their perform
    # methods to further increase confidence that removal is OK.
  end
end
