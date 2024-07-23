# frozen_string_literal: true

module Import
  module GitlabProjects
    module FileAcquisitionStrategies
      class RemoteFileS3
        include ActiveModel::Validations
        include Gitlab::Utils::StrongMemoize

        def self.allow_local_requests?
          ::Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
        end

        validates_presence_of :region, :bucket_name, :file_key, :access_key_id, :secret_access_key
        validates :file_url, addressable_url: {
          schemes: %w[https],
          allow_localhost: allow_local_requests?,
          allow_local_network: allow_local_requests?,
          dns_rebind_protection: true
        }

        validates_with RemoteFileValidator

        # The import itself has a limit of 24h, since the URL is created before the import starts
        # we add an expiration a bit longer to ensure it won't expire during the import.
        URL_EXPIRATION = 28.hours.seconds

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
          @file_url ||= s3_object&.presigned_url(:get, expires_in: URL_EXPIRATION.to_i)
        end

        def content_type
          @content_type ||= s3_object&.content_type
        end

        def content_length
          @content_length ||= s3_object&.content_length.to_i
        end

        # Make the validated params/methods accessible
        def read_attribute_for_validation(key)
          return file_url if key == :file_url

          params[key]
        end

        private

        attr_reader :params, :current_user

        def s3_object
          strong_memoize(:s3_object) do
            build_s3_options
          end
        end

        def build_s3_options
          object = Aws::S3::Object.new(
            params[:bucket_name],
            params[:file_key],
            client: Aws::S3::Client.new(
              region: params[:region],
              access_key_id: params[:access_key_id],
              secret_access_key: params[:secret_access_key]
            )
          )

          # Force validate if the object exists and is accessible
          # Some exceptions are only raised when trying to access the object data
          unless object.exists?
            errors.add(:base, "File not found '#{params[:file_key]}' in '#{params[:bucket_name]}'")
            return
          end

          object
        rescue StandardError => e
          errors.add(:base, "Failed to open '#{params[:file_key]}' in '#{params[:bucket_name]}': #{e.message}")
          nil
        end
      end
    end
  end
end
