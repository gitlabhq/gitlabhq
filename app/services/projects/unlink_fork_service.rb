module Projects
  class UnlinkForkService < BaseService
    def execute
      return unless @project.forked?

      if fork_source = @project.fork_source
        fork_source.lfs_objects.find_each do |lfs_object|
          lfs_object.projects << @project unless lfs_object.projects.include?(@project)
        end

        refresh_forks_count(fork_source)
      end

      merge_requests = @project.fork_network
                         .merge_requests
                         .opened
                         .where.not(target_project: @project)
                         .from_project(@project)

      merge_requests.each do |mr|
        ::MergeRequests::CloseService.new(@project, @current_user).execute(mr)
      end

      @project.fork_network_member.destroy
      @project.forked_project_link.destroy
    end

    def refresh_forks_count(project)
      Projects::ForksCountService.new(project).refresh_cache
    end
  end
end
