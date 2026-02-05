# frozen_string_literal: true

module Packages
  module Conan
    class Package < Packages::Package
      self.allow_legacy_sti_class = true

      has_one :conan_metadatum, inverse_of: :package, class_name: 'Packages::Conan::Metadatum'

      has_many :conan_recipe_revisions, inverse_of: :package, class_name: 'Packages::Conan::RecipeRevision'

      has_many :conan_package_references, inverse_of: :package, class_name: 'Packages::Conan::PackageReference'

      has_many :conan_package_revisions, inverse_of: :package, class_name: 'Packages::Conan::PackageRevision'

      accepts_nested_attributes_for :conan_metadatum

      delegate :recipe, :recipe_path, to: :conan_metadatum, prefix: :conan

      validates :name, :version, format: { with: Gitlab::Regex.conan_recipe_component_regex }
      validate :valid_conan_package_recipe

      scope :with_conan_channel, ->(package_channel) do
        joins(:conan_metadatum).where(packages_conan_metadata: { package_channel: package_channel })
      end

      scope :with_conan_username, ->(package_username) do
        joins(:conan_metadatum).where(packages_conan_metadata: { package_username: package_username })
      end

      scope :preload_conan_metadatum, -> { preload(:conan_metadatum) }

      private

      def valid_conan_package_recipe
        return unless self.class
                        .for_projects(project)
                        .includes(:conan_metadatum)
                        .not_pending_destruction
                        .with_name(name)
                        .with_version(version)
                        .with_conan_channel(conan_metadatum.package_channel)
                        .with_conan_username(conan_metadatum.package_username)
                        .id_not_in(id)
                        .exists?

        errors.add(:base, _('Package recipe already exists'))
      end
    end
  end
end
