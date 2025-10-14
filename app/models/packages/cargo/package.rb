# frozen_string_literal: true

module Packages
  module Cargo
    class Package < Packages::Package
      RESERVED_NAMES = %w[
        nul con prn aux com1 com2 com3 com4 com5 com6 com7 com8 com9
        lpt1 lpt2 lpt3 lpt4 lpt5 lpt6 lpt7 lpt8 lpt9
      ].freeze

      self.allow_legacy_sti_class = true

      has_one :cargo_metadatum, inverse_of: :package, class_name: 'Packages::Cargo::Metadatum'

      validates :version, format: {
        with: Gitlab::Regex.semver_regex,
        message: Gitlab::Regex.semver_regex_message
      }

      validates :name, format: {
        with: Gitlab::Regex.cargo_package_name_regex,
        message: 'must be a valid cargo package name'
      }

      validate :cargo_reserved_name
      validate :cargo_package_version_already_taken

      scope :with_normalized_cargo_name, ->(name) do
        normalized_name = Packages::Cargo.normalize_name(name)
        joins(:cargo_metadatum).where(packages_cargo_metadata: { normalized_name: normalized_name })
      end

      scope :with_normalized_cargo_version, ->(version) do
        normalized_version = Packages::Cargo.normalize_version(version) if version
        joins(:cargo_metadatum).where(packages_cargo_metadata: { normalized_version: normalized_version })
      end

      def self.cargo_package_already_taken?(project_id, package_name, package_version)
        normalized_name = Packages::Cargo.normalize_name(package_name)
        normalized_version = Packages::Cargo.normalize_version(package_version) if package_version

        Packages::Cargo::Package
          .joins(:cargo_metadatum)
          .where(
            project_id: project_id,
            packages_cargo_metadata: {
              normalized_name: normalized_name,
              normalized_version: normalized_version
            }
          )
          .not_pending_destruction
          .exists?
      end

      def cargo_reserved_name
        return unless name.present?

        errors.add(:name, _('is reserved and cannot be used')) if RESERVED_NAMES.include?(name.downcase)
      end

      def cargo_package_version_already_taken
        return unless project && name && version
        return unless self.class.cargo_package_already_taken?(project_id, name, version)

        errors.add(:base, _('Package already exists'))
      end
    end
  end
end
