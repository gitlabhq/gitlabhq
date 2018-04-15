module Projects
  class MoveForksService < BaseMoveRelationsService
    def execute(source_project, remove_remaining_elements: true)
      return unless super && source_project.fork_network

      Project.transaction(requires_new: true) do
        move_forked_project_links
        move_fork_network_members
        update_root_project
        refresh_forks_count

        success
      end
    end

    private

    def move_forked_project_links
      # Update ancestor
      ForkedProjectLink.where(forked_to_project: source_project)
                       .update_all(forked_to_project_id: @project.id)

      # Update the descendants
      ForkedProjectLink.where(forked_from_project: source_project)
                       .update_all(forked_from_project_id: @project.id)
    end

    def move_fork_network_members
      ForkNetworkMember.where(project: source_project).update_all(project_id: @project.id)
      ForkNetworkMember.where(forked_from_project: source_project).update_all(forked_from_project_id: @project.id)
    end

    def update_root_project
      # Update root network project
      ForkNetwork.where(root_project: source_project).update_all(root_project_id: @project.id)
    end

    def refresh_forks_count
      Projects::ForksCountService.new(@project).refresh_cache
    end
  end
end
