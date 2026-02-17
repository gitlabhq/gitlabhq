# frozen_string_literal: true

module Namespaces
  class UnlinkProjectForksService
    def initialize(group, user)
      @group = group
      @user = user
    end

    def execute
      cursor = { current_id: group.id, depth: [group.id] }
      iterator = Gitlab::Database::NamespaceEachBatch.new(namespace_class: Namespaces::ProjectNamespace, cursor: cursor)

      iterator.each_batch(of: 100) do |project_namespace_ids, _new_cursor|
        projects_in_fork_networks(project_namespace_ids).each do |project|
          ::Projects::UnlinkForkService.new(project, user).execute
        end
      end
    end

    private

    attr_reader :group, :user

    def projects_in_fork_networks(project_namespace_ids)
      Project.by_project_namespace(project_namespace_ids).in_fork_network.with_fork_network_associations
    end
  end
end
