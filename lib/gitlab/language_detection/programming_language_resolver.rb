# frozen_string_literal: true

module Gitlab
  # rubocop:disable Gitlab/NamespacedClass -- Gitlab::LanguageDetection is the existing namespace for this workflow.
  class LanguageDetection
    class ProgrammingLanguageResolver
      def initialize(detected_languages)
        @detected_languages = detected_languages
      end

      def execute
        detected_languages.map { |detected_language| resolve(detected_language) }
      end

      private

      attr_reader :detected_languages

      def resolve(detected_language)
        language_by_id = languages_by_id[detected_language.language_id]
        language_by_name = languages_by_name[detected_language.name]

        return language_by_id if conflicting_match?(language_by_id, language_by_name)

        ensure_language(language_by_id || language_by_name, detected_language)
      end

      def conflicting_match?(language_by_id, language_by_name)
        language_by_id && language_by_name && language_by_id != language_by_name
      end

      def ensure_language(language, detected_language)
        return create_language(detected_language) unless language
        return language if language_current?(language, detected_language)

        attrs = {
          name: detected_language.name,
          color: detected_language.color,
          language_id: detected_language.language_id
        }

        language.update!(attrs)

        language
      end

      def language_current?(language, detected_language)
        language.name == detected_language.name &&
          language.color == detected_language.color &&
          language.language_id == detected_language.language_id
      end

      # rubocop:disable CodeReuse/ActiveRecord -- This resolver owns ProgrammingLanguage lookup and creation.
      def languages_by_name
        @languages_by_name ||= ProgrammingLanguage
          .where(name: detected_languages.map(&:name))
          .index_by(&:name)
      end

      def languages_by_id
        @languages_by_id ||= ProgrammingLanguage
          .where(language_id: detected_languages.filter_map(&:language_id))
          .index_by(&:language_id)
      end

      def create_language(detected_language)
        attrs = {
          color: detected_language.color,
          language_id: detected_language.language_id
        }.compact

        ProgrammingLanguage.transaction do
          ProgrammingLanguage.where(name: detected_language.name).first_or_create(attrs)
        end
      rescue ActiveRecord::RecordNotUnique
        find_language_after_conflict(detected_language) || retry
      end

      def find_language_after_conflict(detected_language)
        ProgrammingLanguage.find_by(language_id: detected_language.language_id) ||
          ProgrammingLanguage.find_by(name: detected_language.name)
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end
  end
  # rubocop:enable Gitlab/NamespacedClass
end
