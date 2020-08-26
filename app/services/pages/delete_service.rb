# frozen_string_literal: true

module Pages
  class DeleteService < BaseService
    def execute
      if Feature.enabled?(:async_pages_removal, project)
        PagesRemoveWorker.perform_async(project.id)
      else
        PagesRemoveWorker.new.perform(project.id)
      end
    end
  end
end
