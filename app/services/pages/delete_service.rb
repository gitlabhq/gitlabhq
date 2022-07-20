# frozen_string_literal: true

module Pages
  class DeleteService < BaseService
    def execute
      project.mark_pages_as_not_deployed

      # project.pages_domains.delete_all will just nullify project_id:
      # > If no :dependent option is given, then it will follow the default
      # > strategy for `has_many :through` associations.
      # > The default strategy is :nullify which sets the foreign keys to NULL.
      PagesDomain.for_project(project).delete_all

      publish_deleted_event

      DestroyPagesDeploymentsWorker.perform_async(project.id)
    end

    private

    def publish_deleted_event
      event = Pages::PageDeletedEvent.new(data: {
        project_id: project.id,
        namespace_id: project.namespace_id,
        root_namespace_id: project.root_namespace.id
      })

      Gitlab::EventStore.publish(event)
    end
  end
end
