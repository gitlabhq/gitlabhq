# frozen_string_literal: true

module Packages
  module Composer
    class CacheFile < ApplicationRecord
      include FileStoreMounter

      self.table_name = 'packages_composer_cache_files'

      mount_file_store_uploader Packages::Composer::CacheUploader

      belongs_to :group, -> { where(type: Group.sti_name) }, foreign_key: 'namespace_id'
      belongs_to :namespace

      validates :namespace, presence: true

      scope :with_namespace, ->(namespace) { where(namespace: namespace) }
      scope :with_sha, ->(sha) { where(file_sha256: sha) }
    end
  end
end
