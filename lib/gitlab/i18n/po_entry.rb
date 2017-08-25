module Gitlab
  module I18n
    class PoEntry
      attr_reader :entry_data

      def initialize(entry_data)
        @entry_data = entry_data
      end

      def msgid
        entry_data[:msgid]
      end

      def metadata?
        msgid.empty?
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

      def expected_plurals
        return nil unless metadata?
        return nil unless plural_information

        nplurals = plural_information['nplurals'].to_i
        if nplurals > 0
          nplurals
        end
      end

      # When a translation is a plural, but only has 1 translation, we could be
      # talking about a language in which plural and singular is the same thing.
      # In which case we always translate as a plural.
      def has_singular?
        !plural? || all_translations.size > 1
      end

      private

      def plural_information
        return nil unless metadata?
        return @plural_information if defined?(@plural_information)

        if plural_line = entry_data[:msgstr].detect { |metadata_line| metadata_line.starts_with?('Plural-Forms: ') }
          @plural_information = Hash[plural_line.scan(/(\w+)=([^;\n]+)/)]
        end
      end

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
