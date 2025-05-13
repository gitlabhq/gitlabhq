# frozen_string_literal: true

module Packages
  module Conan
    class PackageRevision < ApplicationRecord
      include ShaAttribute
      include PackageFileable

      sha_attribute :revision

      belongs_to :package, class_name: 'Packages::Conan::Package', inverse_of: :conan_package_revisions
      belongs_to :package_reference, class_name: 'Packages::Conan::PackageReference',
        inverse_of: :package_revisions
      belongs_to :project

      validates :package, :package_reference, :project, presence: true
      validates :revision, presence: true, format: { with: ::Gitlab::Regex.conan_revision_regex_v2 }
      validates :revision, uniqueness: { scope: [:package_id, :package_reference_id] }, on: %i[create update]

      scope :order_by_id_desc, -> { order(id: :desc) }
      scope :by_recipe_revision_and_package_reference, ->(recipe_revision, package_reference) do
        joins(package_reference: :recipe_revision)
          .where(
            packages_conan_recipe_revisions: { revision: recipe_revision },
            packages_conan_package_references: { reference: package_reference }
          )
      end
    end
  end
end
