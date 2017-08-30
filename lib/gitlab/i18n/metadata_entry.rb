module Gitlab
  module I18n
    class MetadataEntry < PoEntry
      def expected_plurals
        return nil unless plural_information

        nplurals = plural_information['nplurals'].to_i
        if nplurals > 0
          nplurals
        end
      end

      private

      def plural_information
        return @plural_information if defined?(@plural_information)

        if plural_line = entry_data[:msgstr].detect { |metadata_line| metadata_line.starts_with?('Plural-Forms: ') }
          @plural_information = Hash[plural_line.scan(/(\w+)=([^;\n]+)/)]
        end
      end
    end
  end
end
