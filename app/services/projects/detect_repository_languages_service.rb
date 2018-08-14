# frozen_string_literal: true

module Projects
  class DetectRepositoryLanguagesService < BaseService
    attr_reader :detected_repository_languages, :programming_languages

    def execute
      repository_languages = project.repository_languages
      detection = Gitlab::LanguageDetection.new(repository, repository_languages)

      matching_programming_languages = ensure_programming_languages(detection)

      RepositoryLanguage.transaction do
        project.repository_languages.where(programming_language_id: detection.deletions).delete_all

        detection.updates.each do |update|
          RepositoryLanguage
            .where(project_id: project.id)
            .where(programming_language_id: update[:programming_language_id])
            .update_all(share: update[:share])
        end

        Gitlab::Database.bulk_insert(
          RepositoryLanguage.table_name,
          detection.insertions(matching_programming_languages)
        )
      end

      project.repository_languages.reload
    end

    private

    def ensure_programming_languages(detection)
      existing_languages = ProgrammingLanguage.where(name: detection.languages)
      return existing_languages if detection.languages.size == existing_languages.size

      missing_languages = detection.languages - existing_languages.map(&:name)
      created_languages = missing_languages.map do |name|
        create_language(name, detection.language_color(name))
      end

      existing_languages + created_languages
    end

    def create_language(name, color)
      ProgrammingLanguage.transaction do
        ProgrammingLanguage.where(name: name).first_or_create(color: color)
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end
end
