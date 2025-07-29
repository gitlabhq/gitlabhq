# frozen_string_literal: true

module Packages
  module Helm
    class MetadataCache < ApplicationRecord
      include FileStoreMounter
      include Packages::Downloadable
      include Packages::Destructible

      enum :status, { default: 0, processing: 1, pending_destruction: 2, error: 3 }

      belongs_to :project, inverse_of: :helm_metadata_caches

      validates :file, :object_storage_key, :project, :size, :channel, presence: true
      validates :channel, length: { minimum: 1, maximum: 255 }, format: { with: Gitlab::Regex.helm_channel_regex }
      validates :channel, uniqueness: { scope: :project_id }

      mount_file_store_uploader MetadataCacheUploader

      before_validation :set_object_storage_key
      attr_readonly :object_storage_key

      private

      def set_object_storage_key
        return unless project_id && channel

        self.object_storage_key = Gitlab::HashedPath.new(
          'packages', 'helm', 'metadata_caches', OpenSSL::Digest::SHA256.hexdigest(channel),
          root_hash: project_id
        ).to_s
      end
    end
  end
end
