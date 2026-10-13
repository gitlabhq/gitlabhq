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
        delete_undetected_languages(detection.deletions)

        detection.updates.each do |update|
          RepositoryLanguage
            .where(project_id: project.id)
            .where(update[:target])
            .update_all(share: update[:share], language_id: update[:language_id])
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

    # rubocop: disable CodeReuse/ActiveRecord -- Rows are matched by stable language_id, with a
    # legacy programming_language_id fallback for rows the backfill has not reached yet.
    def delete_undetected_languages(repository_languages)
      return if repository_languages.empty?

      populated_rows, unpopulated_rows = repository_languages.partition(&:language_id)
      project_languages = RepositoryLanguage.where(project_id: project.id)
      scopes = []

      scopes << project_languages.where(language_id: populated_rows.map(&:language_id)) if populated_rows.any?

      if unpopulated_rows.any?
        scopes << project_languages.where(
          language_id: nil,
          programming_language_id: unpopulated_rows.map(&:programming_language_id)
        )
      end

      scopes.reduce(&:or).delete_all
    end
    # rubocop: enable CodeReuse/ActiveRecord

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
