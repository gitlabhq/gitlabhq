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

    def initialize(project)
      @project = project
    end

    def execute
      GitlabShellWorker.perform_async(:gc, @project.path_with_namespace)
    end
  end
end
