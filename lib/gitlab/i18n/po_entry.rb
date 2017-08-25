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
        @all_translations ||= entry_data.fetch_values(*translation_keys)
      end

      def plural_translations
        return [] unless plural?

        # The singular translation is used if there's only translation. This is
        # the case for languages without plurals.
        return all_translations if all_translations.size == 1

        entry_data.fetch_values(*plural_translation_keys)
      end

      def flag
        entry_data[:flag]
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
