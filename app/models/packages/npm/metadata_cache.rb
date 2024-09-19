# frozen_string_literal: true

module Packages
  module Npm
    class MetadataCache < ApplicationRecord
      include FileStoreMounter
      include Packages::Downloadable
      include Packages::Destructible

      enum status: { default: 0, processing: 1, pending_destruction: 2, error: 3 }

      belongs_to :project, inverse_of: :npm_metadata_caches

      validates :file, :object_storage_key, :package_name, :project, :size, presence: true
      validates :package_name, uniqueness: { scope: :project_id }
      validates :package_name, format: { with: Gitlab::Regex.package_name_regex }
      validates :package_name, format: { with: Gitlab::Regex.npm_package_name_regex }

      mount_file_store_uploader MetadataCacheUploader

      before_validation :set_object_storage_key
      attr_readonly :object_storage_key

      def self.find_or_build(package_name:, project_id:)
        find_or_initialize_by(
          package_name: package_name,
          project_id: project_id
        )
      end

      private

      def set_object_storage_key
        return unless package_name && project_id

        self.object_storage_key = Gitlab::HashedPath.new(
          'packages', 'metadata_caches', 'npm', OpenSSL::Digest::SHA256.hexdigest(package_name),
          root_hash: project_id
        ).to_s
      end
    end
  end
end
