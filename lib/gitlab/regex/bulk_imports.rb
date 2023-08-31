# frozen_string_literal: true

module Gitlab
  module Regex
    module BulkImports
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
