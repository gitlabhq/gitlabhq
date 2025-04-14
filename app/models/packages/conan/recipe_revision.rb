# frozen_string_literal: true

module Packages
  module Conan
    class RecipeRevision < ApplicationRecord
      include ShaAttribute

      sha_attribute :revision

      belongs_to :package, class_name: 'Packages::Conan::Package', inverse_of: :conan_recipe_revisions
      belongs_to :project

      has_many :conan_package_references, inverse_of: :recipe_revision,
        class_name: 'Packages::Conan::PackageReference'
      has_many :file_metadata, inverse_of: :recipe_revision, class_name: 'Packages::Conan::FileMetadatum'

      validates :package, :project, presence: true
      validates :revision, presence: true, format: { with: ::Gitlab::Regex.conan_revision_regex_v2 }
      validates :revision, uniqueness: { scope: :package_id }, on: %i[create update]

      scope :order_by_id_desc, -> { order(id: :desc) }
    end
  end
end
