# frozen_string_literal: true

module Namespaces
  class UnlinkProjectForksWorker
    include ApplicationWorker

    data_consistency :sticky

    queue_namespace :namespaces
    feature_category :source_code_management
    idempotent!
    deduplicate :until_executed, if_deduplicated: :reschedule_once

    def perform(group_id, user_id)
      group = Group.find_by_id(group_id)
      user = User.find_by_id(user_id)

      return unless group && user

      cursor = { current_id: group.id, depth: [group.id] }
      iterator = Gitlab::Database::NamespaceEachBatch.new(namespace_class: Namespace, cursor: cursor)

      iterator.each_batch(of: 100) do |namespace_ids, _new_cursor|
        project_namespace_ids = Namespaces::ProjectNamespace.id_in(namespace_ids)

        projects_in_fork_networks(project_namespace_ids).each do |project|
          ::Projects::UnlinkForkService.new(project, user).execute
        end
      end
    end

    private

    def projects_in_fork_networks(project_namespace_ids)
      Project.by_project_namespace(project_namespace_ids).in_fork_network.with_fork_network_associations
    end
  end
end
