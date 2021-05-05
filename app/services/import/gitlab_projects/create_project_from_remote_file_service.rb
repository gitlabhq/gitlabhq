# frozen_string_literal: true

module Import
  module GitlabProjects
    class CreateProjectFromRemoteFileService < CreateProjectFromUploadedFileService
      FILE_SIZE_LIMIT = 10.gigabytes
      ALLOWED_CONTENT_TYPES = ['application/gzip'].freeze

      validate :valid_remote_import_url?
      validate :validate_file_size
      validate :validate_content_type

      private

      def required_params
        [:path, :namespace, :remote_import_url]
      end

      def project_params
        super
          .except(:file)
          .merge(import_export_upload: ::ImportExportUpload.new(
            remote_import_url: params[:remote_import_url]
          ))
      end

      def valid_remote_import_url?
        ::Gitlab::UrlBlocker.validate!(
          params[:remote_import_url],
          allow_localhost: allow_local_requests?,
          allow_local_network: allow_local_requests?,
          schemes: %w(http https)
        )

        true
      rescue ::Gitlab::UrlBlocker::BlockedUrlError => e
        errors.add(:base, e.message)

        false
      end

      def allow_local_requests?
        ::Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
      end

      def validate_content_type
        if headers['content-type'].blank?
          errors.add(:base, "Missing 'ContentType' header")
        elsif !ALLOWED_CONTENT_TYPES.include?(headers['content-type'])
          errors.add(:base, "Remote file content type '%{content_type}' not allowed. (Allowed content types: %{allowed})" % {
            content_type: headers['content-type'],
            allowed: ALLOWED_CONTENT_TYPES.join(',')
          })
        end
      end

      def validate_file_size
        if headers['content-length'].to_i == 0
          errors.add(:base, "Missing 'ContentLength' header")
        elsif headers['content-length'].to_i > FILE_SIZE_LIMIT
          errors.add(:base, 'Remote file larger than limit. (limit %{limit})' % {
            limit: ActiveSupport::NumberHelper.number_to_human_size(FILE_SIZE_LIMIT)
          })
        end
      end

      def headers
        return {} if params[:remote_import_url].blank? || !valid_remote_import_url?

        @headers ||= Gitlab::HTTP.head(params[:remote_import_url]).headers
      end
    end
  end
end
