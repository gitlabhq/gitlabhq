# Projects::HousekeepingService class
#
# Used for git housekeeping
#
# Ex.
#   Projects::HousekeepingService.new(project).execute
#
module Projects
  class HousekeepingService < BaseService
    LEASE_TIMEOUT = 3600

    class LeaseTaken < StandardError
      def to_s
        "Somebody already triggered housekeeping for this project in the past #{LEASE_TIMEOUT / 60} minutes"
      end
    end

    def initialize(project)
      @project = project
    end

    def execute
      raise LeaseTaken unless try_obtain_lease

      execute_gitlab_shell_gc
    end

    def needed?
      @project.pushes_since_gc >= 10
    end

    def increment!
      Gitlab::Metrics.measure(:increment_pushes_since_gc) do
        @project.increment_pushes_since_gc
      end
    end

    private

    def execute_gitlab_shell_gc
      GitGarbageCollectWorker.perform_async(@project.id)
    ensure
      Gitlab::Metrics.measure(:reset_pushes_since_gc) do
        @project.reset_pushes_since_gc
      end
    end

    def try_obtain_lease
      Gitlab::Metrics.measure(:obtain_housekeeping_lease) do
        lease = ::Gitlab::ExclusiveLease.new("project_housekeeping:#{@project.id}", timeout: LEASE_TIMEOUT)
        lease.try_obtain
      end
    end
  end
end
