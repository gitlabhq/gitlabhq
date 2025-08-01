# frozen_string_literal: true

module Pages
  class DeleteService < BaseService
    def execute
      if current_user.is_a?(User) && !can_remove_pages?
        return ServiceResponse.error(message: _('The current user is not authorized to remove the Pages deployment'),
          reason: :forbidden)
      end

      PagesDeployment.deactivate_all(project)

      # project.pages_domains.delete_all will just nullify project_id:
      # > If no :dependent option is given, then it will follow the default
      # > strategy for `has_many :through` associations.
      # > The default strategy is :nullify which sets the foreign keys to NULL.
      PagesDomain.for_project(project).delete_all

      DestroyPagesDeploymentsWorker.perform_async(project.id)
    end

    private

    def can_remove_pages?
      can?(current_user, :remove_pages, project)
    end
  end
end
