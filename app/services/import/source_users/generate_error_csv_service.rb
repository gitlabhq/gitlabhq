# frozen_string_literal: true

module Import
  module SourceUsers
    class GenerateErrorCsvService
      # This is just to prevent any potential abuse.
      FILESIZE_LIMIT = 10.megabytes

      COLUMN_MAPPING = {
        'Source host' => :source_host,
        'Import type' => :import_type,
        'Source user identifier' => :source_user_identifier,
        'Source user name' => :source_user_name,
        'Source username' => :source_username,
        'GitLab username' => :gitlab_username,
        'GitLab public email' => :gitlab_public_email,
        'Error' => :error
      }.freeze

      # @param data [Array<Hash>] An array of hashes to be converted into CSV
      #   rows. Hash keys must match the values of COLUMN_MAPPING.
      def initialize(data)
        @data = data
      end

      def execute
        ServiceResponse.success(payload: csv_data)
      end

      private

      attr_reader :data

      def csv_data
        CsvBuilder.new(data, COLUMN_MAPPING, replace_newlines: true).render(FILESIZE_LIMIT)
      end
    end
  end
end
