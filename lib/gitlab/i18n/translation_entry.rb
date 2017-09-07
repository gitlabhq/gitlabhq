module Gitlab
  module I18n
    class TranslationEntry
      PERCENT_REGEX = /(?:^|[^%])%(?!{\w*}|[a-z%])/.freeze

      attr_reader :nplurals, :entry_data

      def initialize(entry_data, nplurals)
        @entry_data = entry_data
        @nplurals = nplurals
      end

      def msgid
        entry_data[:msgid]
      end

      def plural_id
        entry_data[:msgid_plural]
      end

      def has_plural?
        plural_id.present?
      end

      def singular_translation
        all_translations.first if has_singular_translation?
      end

      def all_translations
        @all_translations ||= entry_data.fetch_values(*translation_keys)
                                .reject(&:empty?)
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

      def msgid_contains_newlines?
        msgid.is_a?(Array)
      end

      def plural_id_contains_newlines?
        plural_id.is_a?(Array)
      end

      def translations_contain_newlines?
        all_translations.any? { |translation| translation.is_a?(Array) }
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

      private

      def translation_keys
        @translation_keys ||= entry_data.keys.select { |key| key.to_s =~ /\Amsgstr(\[\d+\])?\z/ }
      end
    end
  end
end
