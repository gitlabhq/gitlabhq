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
          RepositoryLanguage
            .where(project_id: project.id)
            .where(programming_language_id: update[:programming_language_id])
            .update_all(share: update[:share])
        end

        Gitlab::Database.main.bulk_insert( # rubocop:disable Gitlab/BulkInsert
          RepositoryLanguage.table_name,
          detection.insertions(matching_programming_languages)
        )

        set_detected_repository_languages
      end

      project.repository_languages.reset
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def ensure_programming_languages(detection)
      existing_languages = ProgrammingLanguage.where(name: detection.languages)
      return existing_languages if detection.languages.size == existing_languages.size

      missing_languages = detection.languages - existing_languages.map(&:name)
      created_languages = missing_languages.map do |name|
        create_language(name, detection.language_color(name))
      end

      existing_languages + created_languages
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def create_language(name, color)
      ProgrammingLanguage.transaction do
        ProgrammingLanguage.where(name: name).first_or_create(color: color)
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def set_detected_repository_languages
      return if project.detected_repository_languages?

      project.update_column(:detected_repository_languages, true)
    end
  end
end
