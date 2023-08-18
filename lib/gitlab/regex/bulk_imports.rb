# frozen_string_literal: true

module Gitlab
  module Regex
    module BulkImports
      def bulk_import_destination_namespace_path_regex
        # This regexp validates the string conforms to rules for a destination_namespace path:
        # i.e does not start with a non-alphanumeric character,
        # contains only alphanumeric characters, forward slashes, periods, and underscores,
        # does not end with a period or forward slash, and has a relative path structure
        # with no http protocol chars or leading or trailing forward slashes
        # eg 'source/full/path' or 'destination_namespace' not 'https://example.com/destination/namespace/path'
        # the regex also allows for an empty string ('') to be accepted as this is allowed in
        # a bulk_import POST request
        @bulk_import_destination_namespace_path_regex ||= %r/((\A\z)|(\A[0-9a-z]*(-_.)?[0-9a-z])(\/?[0-9a-z]*[-_.]?[0-9a-z])+\z)/i
      end

      def bulk_import_source_full_path_regex
        # This regexp validates the string conforms to rules for a source_full_path path:
        # i.e does not start with a non-alphanumeric character except for periods or underscores,
        # contains only alphanumeric characters, forward slashes, periods, and underscores,
        # does not end with a period or forward slash, and has a relative path structure
        # with no http protocol chars or leading or trailing forward slashes
        # eg 'source/full/path' or 'destination_namespace' not 'https://example.com/source/full/path'
        @bulk_import_source_full_path_regex ||= %r/\A([.]?)[^\W](\/?([-_.+]*)*[0-9a-z][-_]*)+\z/i
      end

      def bulk_import_source_full_path_regex_message
        bulk_import_destination_namespace_path_regex_message
      end

      def bulk_import_destination_namespace_path_regex_message
        "must have a relative path structure " \
        "with no HTTP protocol characters, or leading or trailing forward slashes. " \
        "Path segments must not start or end with a special character, " \
        "and must not contain consecutive special characters."
      end
    end
  end
end
