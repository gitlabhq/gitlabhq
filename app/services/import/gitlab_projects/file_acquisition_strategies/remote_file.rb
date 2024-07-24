# frozen_string_literal: true

module Import
  module GitlabProjects
    module FileAcquisitionStrategies
      class RemoteFile
        include ActiveModel::Validations

        def self.allow_local_requests?
          ::Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
        end

        validates :file_url, addressable_url: {
          schemes: %w[https],
          allow_localhost: allow_local_requests?,
          allow_local_network: allow_local_requests?,
          dns_rebind_protection: true
        }

        validates_with RemoteFileValidator, if: -> { !s3_request? }

        def initialize(params:, current_user: nil)
          @params = params
          @current_user = current_user
        end

        def project_params
          @project_params ||= {
            import_export_upload: ::ImportExportUpload.new(remote_import_url: file_url, user: current_user)
          }
        end

        def file_url
          @file_url ||= params[:remote_import_url]
        end

        def content_type
          @content_type ||= headers['content-type']
        end

        def content_length
          @content_length ||= headers['content-length'].to_i
        end

        private

        attr_reader :params, :current_user

        def s3_request?
          headers['Server'] == 'AmazonS3' && headers['x-amz-request-id'].present?
        end

        def headers
          return {} if file_url.blank?

          @headers ||= Gitlab::HTTP.head(file_url, timeout: 1.second).headers
        rescue StandardError => e
          errors.add(:base, "Failed to retrive headers: #{e.message}")

          {}
        end
      end
    end
  end
end
