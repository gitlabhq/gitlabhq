# Projects::HousekeepingService class
#
# Used for git housekeeping
#
# Ex.
#   Projects::HousekeepingService.new(project).execute
#
module Projects
  class HousekeepingService < BaseService
    # Timeout set to 24h
    LEASE_TIMEOUT = 86400

    class LeaseTaken < StandardError
      def to_s
        "Somebody already triggered housekeeping for this project in the past #{LEASE_TIMEOUT / 60} minutes"
      end
    end

    def initialize(project)
      @project = project
    end

    def execute
      lease_uuid = try_obtain_lease
      raise LeaseTaken unless lease_uuid.present?

      yield if block_given?

      execute_gitlab_shell_gc(lease_uuid)
    end

    def needed?
      pushes_since_gc > 0 && period_match? && housekeeping_enabled?
    end

    def increment!
      Gitlab::Metrics.measure(:increment_pushes_since_gc) do
        @project.increment_pushes_since_gc
      end
    end

    private

    def execute_gitlab_shell_gc(lease_uuid)
      GitGarbageCollectWorker.perform_async(@project.id, task, lease_key, lease_uuid)
    ensure
      if pushes_since_gc >= gc_period
        Gitlab::Metrics.measure(:reset_pushes_since_gc) do
          @project.reset_pushes_since_gc
        end
      end
    end

    def try_obtain_lease
      Gitlab::Metrics.measure(:obtain_housekeeping_lease) do
        lease = ::Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT)
        lease.try_obtain
      end
    end

    def lease_key
      "project_housekeeping:#{@project.id}"
    end

    def pushes_since_gc
      @project.pushes_since_gc
    end

    def task
      if pushes_since_gc % gc_period == 0
        :gc
      elsif pushes_since_gc % full_repack_period == 0
        :full_repack
      else
        :incremental_repack
      end
    end

    def period_match?
      [gc_period, full_repack_period, repack_period].any? { |period| pushes_since_gc % period == 0 }
    end

    def housekeeping_enabled?
      Gitlab::CurrentSettings.housekeeping_enabled
    end

    def gc_period
      Gitlab::CurrentSettings.housekeeping_gc_period
    end

    def full_repack_period
      Gitlab::CurrentSettings.housekeeping_full_repack_period
    end

    def repack_period
      Gitlab::CurrentSettings.housekeeping_incremental_repack_period
    end
  end
end
