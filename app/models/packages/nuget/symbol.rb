# frozen_string_literal: true

module Packages
  module Nuget
    class Symbol < ApplicationRecord
      include FileStoreMounter

      belongs_to :package, -> { where(package_type: :nuget) }, inverse_of: :nuget_symbols

      delegate :project_id, to: :package

      validates :package, :file, :file_path, :signature, :object_storage_key, :size, presence: true
      validates :signature, uniqueness: { scope: :file_path }
      validates :object_storage_key, uniqueness: true

      mount_file_store_uploader SymbolUploader

      before_validation :set_object_storage_key, on: :create

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
