# frozen_string_literal: true

module Import
  module Offline
    class Configuration < ApplicationRecord
      self.table_name = 'import_offline_configurations'

      S3_BUCKET_REGEXP = %r{\A[a-z0-9.\-]*\z}

      belongs_to :organization, class_name: 'Organizations::Organization'
      belongs_to :offline_export, class_name: 'Import::Offline::Export'

      encrypts :object_storage_credentials

      validates :provider, :bucket, :export_prefix, :object_storage_credentials, presence: true
      validates :provider, inclusion: { in: :supported_providers }
      validates :bucket, length: { minimum: 3, maximum: 63 }, format: { with: S3_BUCKET_REGEXP }
      validates :object_storage_credentials, json_schema: {
        filename: 'import_offline_configuration_aws_s3_credentials', size_limit: 64.kilobytes
      }, if: :aws?
      validates :object_storage_credentials, json_schema: {
        filename: 'import_offline_configuration_minio_credentials', size_limit: 64.kilobytes
      }, if: :minio?
      validates :endpoint, addressable_url: true, length: { maximum: 255 }, if: :minio?

      enum :provider, {
        aws: 0,
        minio: 1
      }

      after_initialize :generate_export_prefix

      private

      def generate_export_prefix
        return if export_prefix.present?

        self.export_prefix = "#{Time.current.strftime('%F_%H-%M-%S')}_export_#{SecureRandom.alphanumeric(8)}"
      end

      def endpoint
        object_storage_credentials.with_indifferent_access[:endpoint] if object_storage_credentials.present?
      end

      def supported_providers
        # MinIO will eventually be enabled by an application setting disabled by default:
        # https://gitlab.com/gitlab-org/gitlab/-/issues/579705
        providers = self.class.providers
        providers = providers.except(:minio) unless Rails.env.development?
        providers.keys.map(&:to_s)
      end
    end
  end
end
