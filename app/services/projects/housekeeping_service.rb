# Projects::HousekeepingService class
#
# Used for git housekeeping
#
# Ex.
#   Projects::HousekeepingService.new(project, user).execute
#
module Projects
  class HousekeepingService < BaseService
    include Gitlab::ShellAdapter

    def initialize(project)
      @project = project
    end

    def execute
      if gitlab_shell.exists?(@project.path_with_namespace + '.git')
        gitlab_shell.gc(@project.path_with_namespace)
      end
    end
  end
end
