# frozen_string_literal: true

module Gitlab
  class LanguageDetection
    MAX_LANGUAGES = 5

    def initialize(repository, repository_languages)
      @repository = repository
      @repository_languages = repository_languages
    end

    def languages
      detection.keys
    end

    def language_color(name)
      detection.dig(name, :color)
    end

    def language_gitaly_id(name)
      detection.dig(name, :language_id)
    end

    # Newly detected languages, returned in a structure accepted by
    # ApplicationRecord.legacy_bulk_insert
    def insertions(programming_languages)
      languages_by_name = programming_languages.index_by(&:name)

      (languages - previous_language_names).map do |new_lang|
        programming_language = languages_by_name[new_lang]

        {
          project_id: @repository.project.id,
          share: detection[new_lang][:value],
          programming_language_id: programming_language.id,
          language_id: programming_language.language_id
        }
      end
    end

    def updates
      to_update = @repository_languages.select do |lang|
        next unless detection.key?(lang.name)

        expected_language_id = lang.programming_language.language_id

        detection[lang.name][:value] != lang.share || expected_language_id != lang.language_id
      end

      to_update.map do |lang|
        {
          programming_language_id: lang.programming_language_id,
          share: detection[lang.name][:value],
          language_id: lang.programming_language.language_id
        }
      end
    end

    # Returns the ids of the programming languages that do not occur in the detection
    # as current repository languages
    def deletions
      @repository_languages.filter_map do |repo_lang|
        next if detection.key?(repo_lang.name)

        repo_lang.programming_language_id
      end
    end

    private

    def previous_language_names
      @previous_language_names ||= @repository_languages.map(&:name)
    end

    def detection
      @detection ||=
        @repository
        .languages
        .first(MAX_LANGUAGES)
        .index_by { |l| l[:label] }
    end
  end
end
