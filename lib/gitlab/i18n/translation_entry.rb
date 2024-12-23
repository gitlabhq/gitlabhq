# frozen_string_literal: true

module Gitlab
  module I18n
    class TranslationEntry
      PERCENT_REGEX = /(?:^|[^%])%(?!{\w*}|[a-z%])/
      ANGLE_BRACKET_REGEX = /[<>]/
      NAMESPACE_REGEX = /^((?u)\w+|\s)*\|/
      SPACE_REGEX = /[\p{Separator}\u0009-\u000d\u001c-\u001f\u0085\u180e]/
      MULTIPLE_CONSECUTIVE_SPACES_REGEX = /#{SPACE_REGEX}{2,}/o

      attr_reader :nplurals, :entry_data

      def initialize(entry_data:, nplurals:)
        @entry_data = entry_data
        @nplurals = nplurals
      end

      def msgid
        @msgid ||= Array(entry_data[:msgid]).join
      end

      def plural_id
        @plural_id ||= Array(entry_data[:msgid_plural]).join
      end

      def msgid_without_namespace
        @msgid_without_namespace ||= msgid.sub(NAMESPACE_REGEX, '')
      end

      def has_plural?
        plural_id.present?
      end

      def singular_translation
        all_translations.first.to_s if has_singular_translation?
      end

      def all_translations
        @all_translations ||= translation_entries.map { |translation| Array(translation).join }
      end

      def translated?
        all_translations.any?
      end

      def plural_translations
        return [] unless has_plural?
        return [] unless translated?

        @plural_translations ||= if has_singular_translation?
                                   all_translations.drop(1)
                                 else
                                   all_translations
                                 end
      end

      def flag
        entry_data[:flag]
      end

      def has_singular_translation?
        nplurals > 1 || !has_plural?
      end

      def msgid_has_multiple_lines?
        entry_data[:msgid].is_a?(Array)
      end

      def plural_id_has_multiple_lines?
        entry_data[:msgid_plural].is_a?(Array)
      end

      def translations_have_multiple_lines?
        translation_entries.any?(Array)
      end

      def translations_contain_namespace?
        all_translations.any? { |translation| contains_namespace?(translation) }
      end

      def contains_namespace?(string)
        string =~ NAMESPACE_REGEX
      end

      def translations_contain_leading_space?
        all_translations.any? { |translation| contains_leading_space?(translation) }
      end

      def contains_leading_space?(translation)
        translation.match?(/\A,?#{SPACE_REGEX}/o) && !msgid_without_namespace.match?(/\A,?#{SPACE_REGEX}/o)
      end

      def translations_contain_trailing_space?
        all_translations.any? { |translation| contains_trailing_space?(translation) }
      end

      def contains_trailing_space?(translation)
        translation.match?(/#{SPACE_REGEX}\Z/o) && !msgid_without_namespace.match?(/#{SPACE_REGEX}\Z/o)
      end

      def translations_contain_multiple_spaces?
        all_translations.any? { |translation| contains_multiple_spaces?(translation) }
      end

      def contains_multiple_spaces?(translation)
        msgid_matches = msgid_without_namespace.scan(MULTIPLE_CONSECUTIVE_SPACES_REGEX)
        translation_matches = translation.scan(MULTIPLE_CONSECUTIVE_SPACES_REGEX)
        msgid_matches.sort != translation_matches.sort
      end

      def msgid_contains_unescaped_chars?
        contains_unescaped_chars?(msgid)
      end

      def plural_id_contains_unescaped_chars?
        contains_unescaped_chars?(plural_id)
      end

      def translations_contain_unescaped_chars?
        all_translations.any? { |translation| contains_unescaped_chars?(translation) }
      end

      def contains_unescaped_chars?(string)
        string =~ PERCENT_REGEX
      end

      def msgid_contains_potential_html?
        contains_angle_brackets?(msgid)
      end

      def plural_id_contains_potential_html?
        contains_angle_brackets?(plural_id)
      end

      def translations_contain_potential_html?
        all_translations.any? { |translation| contains_angle_brackets?(translation) }
      end

      private

      def contains_angle_brackets?(string)
        string =~ ANGLE_BRACKET_REGEX
      end

      def translation_entries
        @translation_entries ||= entry_data.fetch_values(*translation_keys)
                                   .reject(&:empty?)
      end

      def translation_keys
        @translation_keys ||= entry_data.keys.select { |key| key.to_s =~ /\Amsgstr(\[\d+\])?\z/ }
      end
    end
  end
end
