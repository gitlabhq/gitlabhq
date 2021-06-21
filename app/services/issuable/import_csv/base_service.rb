# frozen_string_literal: true

module Issuable
  module ImportCsv
    class BaseService
      def initialize(user, project, csv_io)
        @user = user
        @project = project
        @csv_io = csv_io
        @results = { success: 0, error_lines: [], parse_error: false }
      end

      def execute
        process_csv
        email_results_to_user

        @results
      end

      private

      def process_csv
        with_csv_lines.each do |row, line_no|
          issuable_attributes = {
            title:       row[:title],
            description: row[:description]
          }

          if create_issuable(issuable_attributes).persisted?
            @results[:success] += 1
          else
            @results[:error_lines].push(line_no)
          end
        end
      rescue ArgumentError, CSV::MalformedCSVError
        @results[:parse_error] = true
      end

      def with_csv_lines
        csv_data = @csv_io.open(&:read).force_encoding(Encoding::UTF_8)
        validate_headers_presence!(csv_data.lines.first)

        CSV.new(
          csv_data,
          col_sep: detect_col_sep(csv_data.lines.first),
          headers: true,
          header_converters: :symbol
        ).each.with_index(2)
      end

      def validate_headers_presence!(headers)
        headers.downcase! if headers
        return if headers && headers.include?('title') && headers.include?('description')

        raise CSV::MalformedCSVError
      end

      def detect_col_sep(header)
        if header.include?(",")
          ","
        elsif header.include?(";")
          ";"
        elsif header.include?("\t")
          "\t"
        else
          raise CSV::MalformedCSVError
        end
      end

      def create_issuable(attributes)
        # NOTE: CSV imports are performed by workers, so we do not have a request context in order
        # to create a SpamParams object to pass to the issuable create service.
        spam_params = nil
        create_issuable_class.new(project: @project, current_user: @user, params: attributes, spam_params: spam_params).execute
      end

      def email_results_to_user
        # defined in ImportCsvService
      end

      def create_issuable_class
        # defined in ImportCsvService
      end
    end
  end
end
