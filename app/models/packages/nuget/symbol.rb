# frozen_string_literal: true

module Packages
  module Nuget
    class Symbol < ApplicationRecord
      include FileStoreMounter
      include ShaAttribute
      include Packages::Destructible

      # Used in destroying stale symbols in worker
      enum :status, default: 0, processing: 1, error: 3

      belongs_to :package, -> { where(package_type: :nuget) }, inverse_of: :nuget_symbols

      delegate :project_id, to: :package

      validates :package, :file, :file_path, :signature, :object_storage_key, :size, presence: true
      validates :signature, uniqueness: { scope: :file_path }
      validates :object_storage_key, uniqueness: true

      sha256_attribute :file_sha256

      mount_file_store_uploader SymbolUploader

      before_validation :set_object_storage_key, on: :create

      scope :stale, -> { where(package_id: nil) }
      scope :pending_destruction, -> { stale.default }

      private

      def set_object_storage_key
        return unless project_id && signature

        self.object_storage_key = Gitlab::HashedPath.new(
          'packages', 'nuget', package_id, 'symbols', OpenSSL::Digest::SHA256.hexdigest(signature),
          root_hash: project_id
        ).to_s
      end
    end
  end
end
