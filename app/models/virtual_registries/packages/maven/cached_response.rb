# frozen_string_literal: true

module VirtualRegistries
  module Packages
    module Maven
      class CachedResponse < ApplicationRecord
        include FileStoreMounter
        include Gitlab::SQL::Pattern

        belongs_to :group
        belongs_to :upstream, class_name: 'VirtualRegistries::Packages::Maven::Upstream', inverse_of: :cached_responses

        validates :group, top_level_group: true, presence: true
        validates :relative_path,
          :object_storage_key,
          :content_type,
          :downloads_count,
          :size,
          presence: true
        validates :relative_path,
          :object_storage_key,
          :upstream_etag,
          :content_type,
          length: { maximum: 255 }
        validates :downloads_count, numericality: { greater_than: 0, only_integer: true }
        validates :relative_path, uniqueness: { scope: :upstream_id }, if: :upstream
        validates :file, presence: true

        mount_file_store_uploader ::VirtualRegistries::CachedResponseUploader

        before_validation :set_object_storage_key,
          if: -> { object_storage_key.blank? && relative_path && upstream && upstream.registry }
        attr_readonly :object_storage_key

        scope :search_by_relative_path, ->(query) do
          fuzzy_search(query, [:relative_path], use_minimum_char_limit: false)
        end

        def filename
          return unless relative_path

          File.basename(relative_path)
        end

        private

        def set_object_storage_key
          self.object_storage_key = Gitlab::HashedPath.new(
            'virtual_registries',
            'packages',
            'maven',
            upstream.registry.id,
            'upstream',
            upstream.id,
            'cached_response',
            OpenSSL::Digest::SHA256.hexdigest(relative_path),
            root_hash: upstream.registry.id
          ).to_s
        end
      end
    end
  end
end
