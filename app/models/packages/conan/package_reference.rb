# frozen_string_literal: true

module Packages
  module Conan
    class PackageReference < ApplicationRecord
      include ShaAttribute

      REFERENCE_LENGTH_MAX = 40
      MAX_INFO_SIZE = 20_000

      sha_attribute :reference

      belongs_to :package, class_name: 'Packages::Conan::Package',
        inverse_of: :conan_package_references
      belongs_to :recipe_revision, class_name: 'Packages::Conan::RecipeRevision',
        inverse_of: :conan_package_references
      belongs_to :project

      has_many :package_revisions, inverse_of: :package_reference, class_name: 'Packages::Conan::PackageRevision'
      has_many :file_metadata, inverse_of: :package_reference, class_name: 'Packages::Conan::FileMetadatum'

      validates :package, :project, presence: true
      validates :reference, presence: true, bytesize: { maximum: -> { REFERENCE_LENGTH_MAX } }
      validates :reference, uniqueness: { scope: %i[package_id recipe_revision_id] }, on: %i[create update]

      validates :info, json_schema: { filename: 'conan_package_info', detail_errors: true }
      validate :ensure_info_size

      def self.for_package_id_and_reference(package_id, reference)
        where(package_id: package_id, reference: reference)
      end

      private

      def ensure_info_size
        return if info.to_s.size <= MAX_INFO_SIZE

        errors.add(:info, :too_large,
          message: format(
            _('conaninfo is too large. Maximum size is %{max_size} characters'),
            max_size: MAX_INFO_SIZE
          )
        )
      end
    end
  end
end
