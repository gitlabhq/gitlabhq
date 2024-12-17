# frozen_string_literal: true

module Projects
  class UnlinkForkService < BaseService
    # Close existing MRs coming from the project and remove it from the fork network
    def execute(refresh_statistics: true)
      fork_network = @project.fork_network
      forked_from = @project.forked_from_project

      return unless fork_network

      log_info(message: "UnlinkForkService: Unlinking fork network", fork_network_id: fork_network.id)

      merge_requests = fork_network
                         .merge_requests
                         .opened
                         .from_and_to_forks(@project)

      merge_requests.find_each do |mr|
        ::MergeRequests::CloseService.new(project: @project, current_user: @current_user).execute(mr)
        log_info(message: "UnlinkForkService: Closed merge request", merge_request_id: mr.id)
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

        @project.leave_pool_repository
      end

      # rubocop: disable Cop/InBatches
      Project.uncached do
        @project.forked_to_members.in_batches do |fork_relation|
          fork_relation.pluck(:id).each do |fork_id| # rubocop: disable CodeReuse/ActiveRecord
            log_info(message: "UnlinkForkService: Unlinked fork of root_project", project_id: @project.id, forked_project_id: fork_id)
          end
        end
      end
      # rubocop: enable Cop/InBatches

      ProjectCacheWorker.perform_async(project.id, [], %w[repository_size]) if refresh_statistics

      # When the project getting out of the network is a node with parent
      # and children, both the parent and the node needs a cache refresh.
      [forked_from, @project].compact.each do |project|
        refresh_forks_count(project)
      end
    end

    private

    def refresh_forks_count(project)
      Projects::ForksCountService.new(project).refresh_cache
    end
  end
end

Projects::UnlinkForkService.prepend_mod_with('Projects::UnlinkForkService')
