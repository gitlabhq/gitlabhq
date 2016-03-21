# Projects::HousekeepingService class
#
# Used for git housekeeping
#
# Ex.
#   Projects::HousekeepingService.new(project).execute
#
module Projects
  class HousekeepingService < BaseService
    include Gitlab::ShellAdapter

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
      raise LeaseTaken if !try_obtain_lease

      GitlabShellOneShotWorker.perform_async(:gc, @project.path_with_namespace)
    ensure
      @project.update_column(:pushes_since_gc, 0)
    end

    def needed?
      @project.pushes_since_gc >= 10
    end

    def increment!
      @project.increment!(:pushes_since_gc)
    end

    private

    def try_obtain_lease
      lease = ::Gitlab::ExclusiveLease.new("project_housekeeping:#{@project.id}", timeout: LEASE_TIMEOUT)
      lease.try_obtain
    end
  end
end
