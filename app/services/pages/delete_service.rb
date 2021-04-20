# frozen_string_literal: true

module Pages
  class DeleteService < BaseService
    def execute
      project.mark_pages_as_not_deployed # prevents domain from updating config when deleted
      project.pages_domains.delete_all

      DestroyPagesDeploymentsWorker.perform_async(project.id)

      # TODO: remove this call https://gitlab.com/gitlab-org/gitlab/-/issues/320775
      PagesRemoveWorker.perform_async(project.id) if ::Settings.pages.local_store.enabled
    end
  end
end
