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

    # Newly detected languages, returned in a structure accepted by
    # Gitlab::Database.bulk_insert
    def insertions(programming_languages)
      lang_to_id = programming_languages.to_h { |p| [p.name, p.id] }

      (languages - previous_language_names).map do |new_lang|
        {
          project_id: @repository.project.id,
          share: detection[new_lang][:value],
          programming_language_id: lang_to_id[new_lang]
        }
      end
    end

    # updates analyses which records only require updating of their share
    def updates
      to_update = @repository_languages.select do |lang|
        detection.key?(lang.name) && detection[lang.name][:value] != lang.share
      end

      to_update.map do |lang|
        { programming_language_id: lang.programming_language_id, share: detection[lang.name][:value] }
      end
    end

    # Returns the ids of the programming languages that do not occur in the detection
    # as current repository languages
    def deletions
      @repository_languages.map do |repo_lang|
        next if detection.key?(repo_lang.name)

        repo_lang.programming_language_id
      end.compact
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
        .to_h { |l| [l[:label], l] }
    end
  end
end
