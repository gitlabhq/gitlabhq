# frozen_string_literal: true

module Gitlab
  module I18n
    class MetadataEntry
      attr_reader :entry_data

      # Avoid testing too many plurals if `nplurals` was incorrectly set.
      # Based on info on https://www.gnu.org/software/gettext/manual/html_node/Plural-forms.html
      # which mentions special cases for numbers ending in 2 digits
      MAX_FORMS_TO_TEST = 101

      def initialize(entry_data)
        @entry_data = entry_data
      end

      def expected_forms
        return unless plural_information

        plural_information['nplurals'].to_i
      end

      def forms_to_test
        @forms_to_test ||= [expected_forms, MAX_FORMS_TO_TEST].compact.min
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
