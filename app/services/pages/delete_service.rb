# frozen_string_literal: true

module Pages
  class DeleteService < BaseService
    def execute
      PagesRemoveWorker.perform_async(project.id)
    end
  end
end
