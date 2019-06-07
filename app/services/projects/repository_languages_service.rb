# frozen_string_literal: true

module Projects
  class RepositoryLanguagesService < BaseService
    def execute
      perform_language_detection unless project.detected_repository_languages?
      persisted_repository_languages
    end

    private

    def perform_language_detection
      if persisted_repository_languages.blank?
        ::DetectRepositoryLanguagesWorker.perform_async(project.id)
      else
        project.update_column(:detected_repository_languages, true)
      end
    end

    def persisted_repository_languages
      project.repository_languages
    end
  end
end
