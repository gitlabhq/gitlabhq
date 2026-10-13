# frozen_string_literal: true

module Gitlab
  class LanguageDetection
    MAX_LANGUAGES = 5
    DetectedLanguage = Struct.new(:name, :share, :color, :language_id, keyword_init: true)

    def initialize(repository, repository_languages)
      @repository = repository
      @repository_languages = repository_languages
    end

    def languages
      detected_languages.map(&:name)
    end

    def detected_languages
      @detected_languages ||= detection.map do |name, attributes|
        DetectedLanguage.new(
          name: name,
          share: attributes[:value],
          color: attributes[:color],
          language_id: attributes[:language_id]
        )
      end
    end

    def insertions(programming_languages)
      languages_by_name = programming_languages.index_by(&:name)
      languages_by_id = programming_languages
        .select(&:language_id)
        .index_by(&:language_id)

      new_languages.map do |detected_language|
        programming_language = languages_by_id[detected_language.language_id] ||
          languages_by_name[detected_language.name]

        {
          project_id: @repository.project.id,
          share: detected_language.share,
          programming_language_id: programming_language.id,
          language_id: programming_language.language_id
        }
      end
    end

    def updates
      to_update = @repository_languages.select do |lang|
        next unless detection.key?(lang.name)

        expected_language_id = lang.resolved_programming_language.language_id

        detection[lang.name][:value] != lang.share || expected_language_id != lang.language_id
      end

      to_update.map do |lang|
        {
          target: row_target(lang),
          share: detection[lang.name][:value],
          language_id: lang.resolved_programming_language.language_id
        }
      end
    end

    # Returns the current repository languages that do not occur in the detection.
    # Callers need the rows themselves to target them by stable language_id.
    def deletions
      @repository_languages.reject { |repo_lang| detection.key?(repo_lang.name) }
    end

    private

    # programming_language_id carries the source cell's programming_languages.id after an
    # organization move, so rows are targeted by the stable language_id. The legacy fallback
    # is only needed while the language_id backfill can still leave the column NULL.
    def row_target(repository_language)
      return { language_id: repository_language.language_id } if repository_language.language_id

      { language_id: nil, programming_language_id: repository_language.programming_language_id }
    end

    def previous_language_names
      @previous_language_names ||= @repository_languages.map(&:name)
    end

    def new_languages
      detected_languages.reject { |language| previous_language_names.include?(language.name) }
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
