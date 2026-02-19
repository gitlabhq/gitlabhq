# frozen_string_literal: true

module Packages
  module Composer
    class Metadatum < ApplicationRecord
      TARGET_SHA_MAX_LENGTH = 64.bytes
      VERSION_CACHE_SHA_MAX_LENGTH = 255.bytes

      self.table_name = 'packages_composer_metadata'
      self.primary_key = :package_id

      belongs_to :package, class_name: 'Packages::Composer::Sti::Package', inverse_of: :composer_metadatum

      validates :package, :target_sha, :composer_json, presence: true
      validates :target_sha, bytesize: { maximum: -> { TARGET_SHA_MAX_LENGTH } }, if: :target_sha_changed?
      validates :version_cache_sha, bytesize: { maximum: -> { VERSION_CACHE_SHA_MAX_LENGTH } }, if: :version_cache_sha_changed?

      scope :for_package, ->(name, project_id) { joins(:package).where(packages_packages: { name: name, project_id: project_id, package_type: Packages::Package.package_types[:composer] }) }
      scope :locked_for_update, -> { lock('FOR UPDATE') }
    end
  end
end
