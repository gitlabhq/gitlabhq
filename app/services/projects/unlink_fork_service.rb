# frozen_string_literal: true

module Projects
  class UnlinkForkService < BaseService
    # If a fork is given, it:
    #
    # - Saves LFS objects to the root project
    # - Close existing MRs coming from it
    # - Is removed from the fork network
    #
    # If a root of fork(s) is given, it does the same,
    # but not updating LFS objects (there'll be no related root to cache it).
    def execute
      fork_network = @project.fork_network

      return unless fork_network

      save_lfs_objects

      merge_requests = fork_network
                         .merge_requests
                         .opened
                         .from_and_to_forks(@project)

      merge_requests.find_each do |mr|
        ::MergeRequests::CloseService.new(@project, @current_user).execute(mr)
      end

      Project.transaction do
        # Get out of the fork network as a member and
        # remove references from all its direct forks.
        @project.fork_network_member.destroy
        @project.forked_to_members.update_all(forked_from_project_id: nil)

        # The project is not necessarily a fork, so update the fork network originating
        # from this project
        if fork_network = @project.root_of_fork_network
          fork_network.update(root_project: nil, deleted_root_project_name: @project.full_name)
        end
      end

      # When the project getting out of the network is a node with parent
      # and children, both the parent and the node needs a cache refresh.
      [@project.forked_from_project, @project].compact.each do |project|
        refresh_forks_count(project)
      end
    end

    private

    def refresh_forks_count(project)
      Projects::ForksCountService.new(project).refresh_cache
    end

    def save_lfs_objects
      return unless @project.forked?

      lfs_storage_project = @project.lfs_storage_project

      return unless lfs_storage_project
      return if lfs_storage_project == @project # that project is being unlinked

      lfs_storage_project.lfs_objects.find_each do |lfs_object|
        lfs_object.projects << @project unless lfs_object.projects.include?(@project)
      end
    end
  end
end
