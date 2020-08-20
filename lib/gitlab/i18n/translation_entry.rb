# frozen_string_literal: true

module Gitlab
  module I18n
    class TranslationEntry
      PERCENT_REGEX = /(?:^|[^%])%(?!{\w*}|[a-z%])/.freeze
      ANGLE_BRACKET_REGEX = /[<>]/.freeze

      attr_reader :nplurals, :entry_data, :html_allowed

      def initialize(entry_data:, nplurals:, html_allowed:)
        @entry_data = entry_data
        @nplurals = nplurals
        @html_allowed = html_allowed
      end

      def msgid
        @msgid ||= Array(entry_data[:msgid]).join
      end

      def plural_id
        @plural_id ||= Array(entry_data[:msgid_plural]).join
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
        translation_entries.any? { |translation| translation.is_a?(Array) }
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

      def msgid_html_allowed?
        html_allowed.present?
      end

      def plural_id_html_allowed?
        html_allowed.present? && html_allowed['plural_id'] == plural_id
      end

      def translations_html_allowed?
        msgid_html_allowed? && html_allowed['translations'].present? && all_translations.all? do |translation|
          html_allowed['translations'].include?(translation)
        end
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
