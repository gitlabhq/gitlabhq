# frozen_string_literal: true

module Import
  module GitlabProjects
    # Validates the given object's #content_type and #content_length accordingly
    # with the Project Import requirements
    class RemoteFileValidator < ActiveModel::Validator
      FILE_SIZE_LIMIT = 10.gigabytes
      ALLOWED_CONTENT_TYPES = [
        'application/gzip',
        # S3 uses different file types
        'application/x-tar',
        'application/x-gzip'
      ].freeze

      def validate(record)
        validate_content_length(record)
        validate_content_type(record)
      end

      private

      def validate_content_length(record)
        if record.content_length.to_i <= 0
          record.errors.add(:content_length, :size_too_small, file_size: humanize(1.byte))
        elsif record.content_length > FILE_SIZE_LIMIT
          record.errors.add(:content_length, :size_too_big, file_size: humanize(FILE_SIZE_LIMIT))
        end
      end

      def humanize(number)
        ActiveSupport::NumberHelper.number_to_human_size(number)
      end

      def validate_content_type(record)
        return if ALLOWED_CONTENT_TYPES.include?(record.content_type)

        record.errors.add(:content_type, "'%{content_type}' not allowed. (Allowed: %{allowed})" % {
          content_type: record.content_type,
          allowed: ALLOWED_CONTENT_TYPES.join(', ')
        })
      end
    end
  end
end
