# frozen_string_literal: true

module Issuable
  module ImportCsv
    class BaseService < ::ImportCsv::BaseService
      extend ::Gitlab::Utils::Override

      private

      override :attributes_for
      def attributes_for(row)
        {
          title: row[:title],
          description: row[:description],
          due_date: row[:due_date]
        }
      end

      override :validate_headers_presence!
      def validate_headers_presence!(headers)
        headers.downcase! if headers
        return if headers && headers.include?('title') && headers.include?('description')

        raise CSV::MalformedCSVError.new('Invalid CSV format - missing required headers.', 1)
      end
    end
  end
end
