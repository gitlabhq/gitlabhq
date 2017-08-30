module Gitlab
  module I18n
    class TranslationEntry < PoEntry
      def msgid
        entry_data[:msgid]
      end

      def plural_id
        entry_data[:msgid_plural]
      end

      def plural?
        plural_id.present?
      end

      def singular_translation
        plural? ? entry_data['msgstr[0]'] : entry_data[:msgstr]
      end

      def all_translations
        @all_translations ||= entry_data.fetch_values(*translation_keys).reject(&:empty?)
      end

      def translated?
        all_translations.any?
      end

      def plural_translations
        return [] unless plural?
        return [] unless translated?

        # The singular translation is used if there's only translation. This is
        # the case for languages without plurals.
        return all_translations if all_translations.size == 1

        entry_data.fetch_values(*plural_translation_keys)
      end

      def flag
        entry_data[:flag]
      end

      # When a translation is a plural, but only has 1 translation, we could be
      # talking about a language in which plural and singular is the same thing.
      # In which case we always translate as a plural.
      def has_singular?
        !plural? || all_translations.size > 1
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

      private

      def plural_translation_keys
        @plural_translation_keys ||= translation_keys.select do |key|
          plural_index = key.scan(/\d+/).first.to_i
          plural_index > 0
        end
      end

      def translation_keys
        @translation_keys ||= if plural?
                                entry_data.keys.select { |key| key =~ /msgstr\[\d+\]/ }
                              else
                                [:msgstr]
                              end
      end
    end
  end
end
