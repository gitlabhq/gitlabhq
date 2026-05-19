# frozen_string_literal: true

module Packages
  module Rubygems
    class SpecFile < ApplicationRecord
      include FileStoreMounter
      include ObjectStorable
      include Packages::Destructible

      STORE_COLUMN = :file_store

      enum :status, { default: 0, processing: 1, pending_destruction: 2, error: 3 }

      belongs_to :project, inverse_of: :rubygems_spec_files

      validates :file, :object_storage_key, :file_name, :project, :size, presence: true
      validates :file_name, uniqueness: { scope: :project_id }

      mount_file_store_uploader SpecFileUploader

      before_validation :set_object_storage_key, on: :create
      attr_readonly :object_storage_key

      private

      def set_object_storage_key
        return unless project_id && file_name

        self.object_storage_key = Gitlab::HashedPath.new(
          'packages', 'rubygems', 'spec_files', OpenSSL::Digest::SHA256.hexdigest(file_name),
          root_hash: project_id
        ).to_s
      end
    end
  end
end
