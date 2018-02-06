class Admin::HealthCheckController < Admin::ApplicationController
  def show
    @errors = HealthCheck::Utils.process_checks(['standard'])
    @failing_storage_statuses = Gitlab::Git::Storage::Health.for_failing_storages
  end

  def reset_storage_health
    Gitlab::Git::Storage::FailureInfo.reset_all!
    redirect_to admin_health_check_path,
                notice: _('Git storage health information has been reset')
  end
end
