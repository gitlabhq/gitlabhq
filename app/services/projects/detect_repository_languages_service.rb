# frozen_string_literal: true

module Projects
  class DetectRepositoryLanguagesService < BaseService
    attr_reader :programming_languages

    # rubocop: disable CodeReuse/ActiveRecord
    def execute
      repository_languages = project.repository_languages
      detection = Gitlab::LanguageDetection.new(repository, repository_languages)

      matching_programming_languages = ensure_programming_languages(detection)

      RepositoryLanguage.transaction do
        RepositoryLanguage.where(project_id: project.id, programming_language_id: detection.deletions).delete_all

        detection.updates.each do |update|
          attrs = { share: update[:share], language_id: update[:language_id] }

          RepositoryLanguage
            .where(project_id: project.id)
            .where(programming_language_id: update[:programming_language_id])
            .update_all(attrs)
        end

        ApplicationRecord.legacy_bulk_insert( # rubocop:disable Gitlab/BulkInsert
          RepositoryLanguage.table_name,
          detection.insertions(matching_programming_languages)
        )

        set_detected_repository_languages
      end

      project.repository_languages.reset
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def ensure_programming_languages(detection)
      Gitlab::LanguageDetection::ProgrammingLanguageResolver.new(detection.detected_languages).execute
    end

    def set_detected_repository_languages
      return if project.detected_repository_languages?

      project.update_column(:detected_repository_languages, true)
    end
  end
end

Projects::DetectRepositoryLanguagesService.prepend_mod_with('Projects::DetectRepositoryLanguagesService')
