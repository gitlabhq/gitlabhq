# frozen_string_literal: true

module VirtualRegistries
  module Packages
    module Maven
      class CachedResponse < ApplicationRecord
        include FileStoreMounter
        include Gitlab::SQL::Pattern

        belongs_to :group
        belongs_to :upstream, class_name: 'VirtualRegistries::Packages::Maven::Upstream', inverse_of: :cached_responses

        # Used in destroying stale cached responses in DestroyOrphanCachedResponsesWorker
        enum :status, default: 0, processing: 1, error: 3

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
        scope :orphan, -> { where(upstream: nil) }
        scope :pending_destruction, -> { orphan.default }

        def self.next_pending_destruction
          pending_destruction.lock('FOR UPDATE SKIP LOCKED').take
        end

        # create or update a cached response identified by the upstream, group_id and relative_path
        # Given that we have chances that this function is not executed in isolation, we can't use
        # safe_find_or_create_by.
        # We are using the check existence and rescue alternative.
        def self.create_or_update_by!(upstream:, group_id:, relative_path:, updates: {})
          find_or_initialize_by(upstream: upstream, group_id: group_id, relative_path: relative_path).tap do |record|
            record.increment(:downloads_count) if record.persisted?
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

        # The registry parameter is there to counter a bug with has_one :through records that will fire an extra
        # database query.
        # See https://github.com/rails/rails/issues/51817.
        def stale?(registry:)
          return true unless registry

          (upstream_checked_at + registry.cache_validity_hours.hours).past?
        end

        def bump_statistics(include_upstream_checked_at: false)
          now = Time.zone.now
          updates = { downloaded_at: now, downloads_count: downloads_count + 1 }
          updates[:upstream_checked_at] = now if include_upstream_checked_at
          update_columns(**updates)
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
