# frozen_string_literal: true

module Import
  module UserMapping
    class ReassignmentCsvValidator
      include Gitlab::Utils::StrongMemoize
      include SafeFormatHelper

      REQUIRED_HEADERS = [
        # :source_host, :import_type and :source_user_identifier are required to
        # identify the Import::SourceUser
        :source_host,
        :import_type,
        :source_user_identifier,
        # :gitlab_username and :gitlab_public_email are required to identify
        # the user on the destination instance to reassign to
        :gitlab_username,
        :gitlab_public_email
      ].freeze

      attr_reader :errors

      def initialize(raw_csv)
        @raw_csv = raw_csv
        @errors = []
      end

      def valid?
        validate!

        errors.empty?
      end
      strong_memoize_attr :valid?

      def formatted_errors
        return if errors.empty?

        safe_format(
          s_('UserMapping|The following errors are preventing the sheet from being processed: %{errors}'),
          { errors: errors.join(' ') }
        )
      end

      def csv_data
        CSV.parse(
          raw_csv,
          headers: true,
          header_converters: :symbol
        )
      end
      strong_memoize_attr :csv_data

      private

      attr_reader :raw_csv

      def validate!
        check_headers
        check_duplicates
      end

      def check_headers
        headers = csv_data.headers

        return unless headers.empty? || REQUIRED_HEADERS.any? { |header| headers.exclude?(header.downcase) }

        errors << s_('UserMapping|The provided CSV was not correctly formatted.')
      end

      def check_duplicates
        email_addresses = Set.new
        usernames = Set.new

        csv_data.each do |row_array|
          row = row_array.to_h

          dupe_key = "#{row[:import_type]}/#{row[:source_host]}/"

          email = row[:gitlab_public_email].presence
          username = row[:gitlab_username].presence

          duplicate_emails = email && !email_addresses.add?("#{dupe_key}/#{email}")
          duplicate_usernames = username && !usernames.add?("#{dupe_key}/#{username}")

          if duplicate_emails || duplicate_usernames
            errors << s_('UserMapping|The provided spreadsheet contains duplicate email addresses or usernames.')
            break
          end
        end
      end
    end
  end
end
