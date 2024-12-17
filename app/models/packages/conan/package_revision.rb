# frozen_string_literal: true

module Packages
  module Conan
    class PackageRevision < ApplicationRecord
      include ShaAttribute

      REVISION_LENGTH_MAX = 40

      sha_attribute :revision

      belongs_to :package, class_name: 'Packages::Conan::Package', inverse_of: :conan_package_revisions
      belongs_to :package_reference, class_name: 'Packages::Conan::PackageReference',
        inverse_of: :package_revisions
      belongs_to :project

      has_many :file_metadata, inverse_of: :package_revision, class_name: 'Packages::Conan::FileMetadatum'

      validates :package, :package_reference, :project, presence: true
      validates :revision, presence: true, bytesize: { maximum: -> { REVISION_LENGTH_MAX } },
        uniqueness: { scope: [:package_id, :package_reference_id] }
    end
  end
end
