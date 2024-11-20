# frozen_string_literal: true

module VirtualRegistries
  module Packages
    module Maven
      class CachedResponse < ApplicationRecord
        include FileStoreMounter
        include Gitlab::SQL::Pattern
        include ::UpdateNamespaceStatistics

        belongs_to :group
        belongs_to :upstream, class_name: 'VirtualRegistries::Packages::Maven::Upstream', inverse_of: :cached_responses

        alias_attribute :namespace, :group

        update_namespace_statistics namespace_statistics_name: :dependency_proxy_size

        # Used in destroying stale cached responses in DestroyOrphanCachedResponsesWorker
        enum :status, default: 0, processing: 1, pending_destruction: 2, error: 3

        ignore_column :downloads_count, remove_with: '17.8', remove_after: '2024-12-23'
        ignore_column :downloaded_at, remove_with: '17.9', remove_after: '2025-01-23'

        validates :group, top_level_group: true, presence: true
        validates :relative_path,
          :object_storage_key,
          :content_type,
          :size,
          :file_sha1,
          presence: true
        validates :relative_path,
          :object_storage_key,
          :upstream_etag,
          :content_type,
          length: { maximum: 255 }
        validates :file_final_path, length: { maximum: 1024 }
        validates :relative_path,
          uniqueness: { scope: [:upstream_id, :status] },
          if: -> { upstream.present? && default? }
        validates :file, presence: true

        mount_file_store_uploader ::VirtualRegistries::CachedResponseUploader

        before_validation :set_object_storage_key,
          if: -> { object_storage_key.blank? && relative_path && upstream && upstream.registry }
        attr_readonly :object_storage_key

        scope :search_by_relative_path, ->(query) do
          fuzzy_search(query, [:relative_path], use_minimum_char_limit: false)
        end
        scope :for_group, ->(group) { where(group: group) }

        def self.next_pending_destruction
          pending_destruction.lock('FOR UPDATE SKIP LOCKED').take
        end

        # create or update a cached response identified by the upstream, group_id and relative_path
        # Given that we have chances that this function is not executed in isolation, we can't use
        # safe_find_or_create_by.
        # We are using the check existence and rescue alternative.
        def self.create_or_update_by!(upstream:, group_id:, relative_path:, updates: {})
          default.find_or_initialize_by(
            upstream: upstream,
            group_id: group_id,
            relative_path: relative_path
          ).tap do |record|
            record.update!(**updates)
          end
        rescue ActiveRecord::RecordInvalid => invalid
          # in case of a race condition, retry the block
          retry if invalid.record&.errors&.of_kind?(:relative_path, :taken)

          # otherwise, bubble up the error
          raise
        end

        def filename
          return unless relative_path

          File.basename(relative_path)
        end

        def stale?
          return true unless upstream
          return false if upstream.cache_validity_hours == 0

          (upstream_checked_at + upstream.cache_validity_hours.hours).past?
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
