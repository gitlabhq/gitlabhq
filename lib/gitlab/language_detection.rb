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
