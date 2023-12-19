# frozen_string_literal: true

module BulkImports
  class FinishProjectImportWorker
    include ApplicationWorker

    feature_category :importers
    sidekiq_options retry: 3
    data_consistency :sticky

    idempotent!

    def perform(project_id)
      project = Project.find_by_id(project_id)
      return unless project

      project.after_import
    end
  end
end
