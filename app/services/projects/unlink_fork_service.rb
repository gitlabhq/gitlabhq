module Projects
  class UnlinkForkService < BaseService
    def execute
      return unless @project.forked?

      @project.forked_from_project.lfs_objects.find_each do |lfs_object|
        lfs_object.projects << @project
      end

      merge_requests = @project.forked_from_project.merge_requests.opened.from_project(@project)

      merge_requests.each do |mr|
        ::MergeRequests::CloseService.new(@project, @current_user).execute(mr)
      end

      refresh_forks_count(@project.forked_from_project)

      @project.forked_project_link.destroy
    end

    def refresh_forks_count(project)
      Projects::ForksCountService.new(project).refresh_cache
    end
  end
end
