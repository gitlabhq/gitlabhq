# frozen_string_literal: true

module Pages
  class DeleteGroupPagesDeploymentsWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :always
    feature_category :pages
    idempotent!

    def handle_event(event)
      group_id = event.data[:group_id]
      return unless group_id

      group = Group.find_by_id(group_id)
      return unless group

      cursor = { current_id: group_id, depth: [group_id] }
      iterator = Gitlab::Database::NamespaceEachBatch.new(namespace_class: Namespace, cursor: cursor)

      iterator.each_batch(of: 100) do |namespace_ids, _new_cursor|
        project_namespaces = Namespaces::ProjectNamespace.id_in(namespace_ids)

        projects_with_pages(project_namespaces).each do |project|
          user = project.owner
          next unless user

          ::Pages::DeleteService.new(project, user).execute
        end
      end
    end

    private

    def projects_with_pages(project_namespaces)
      Project.by_project_namespace(project_namespaces).with_pages_deployed
    end
  end
end
