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

      DestroyPagesDeploymentsWorker.perform_async(project.id)
    end
  end
end
