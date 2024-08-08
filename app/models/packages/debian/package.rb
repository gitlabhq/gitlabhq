# frozen_string_literal: true

module Packages
  module Debian
    class Package < Packages::Package
      self.allow_legacy_sti_class = true

      has_one :publication, inverse_of: :package, class_name: 'Packages::Debian::Publication'
      has_one :distribution, through: :publication, source: :distribution, inverse_of: :packages,
        class_name: 'Packages::Debian::ProjectDistribution'

      accepts_nested_attributes_for :publication

      delegate :codename, :suite, to: :distribution, prefix: :distribution

      validates :name, format: { with: Gitlab::Regex.debian_package_name_regex }, if: :version?
      validates :name, inclusion: { in: [Packages::Debian::INCOMING_PACKAGE_NAME] }, unless: :version?

      validates :version,
        presence: true,
        format: { with: Gitlab::Regex.debian_version_regex },
        if: :version?
      validate :forbidden_changes

      scope :with_codename, ->(codename) do
        joins(:distribution).where(Packages::Debian::ProjectDistribution.table_name => { codename: codename })
      end

      scope :with_codename_or_suite, ->(codename_or_suite) do
        joins(:distribution)
          .where(Packages::Debian::ProjectDistribution.table_name => { codename: codename_or_suite })
          .or(where(Packages::Debian::ProjectDistribution.table_name => { suite: codename_or_suite }))
      end

      scope :preload_debian_file_metadata, -> { preload(package_files: :debian_file_metadatum) }

      def self.incoming_package!
        default
          .with_version(nil)
          .find_by!(name: Packages::Debian::INCOMING_PACKAGE_NAME)
      end

      def self.existing_packages_with(name:, version:)
        with_name(name)
          .with_version(version)
          .not_pending_destruction
      end

      def incoming?
        name == Packages::Debian::INCOMING_PACKAGE_NAME && version.nil?
      end

      private

      def forbidden_changes
        return unless persisted?

        # Debian incoming
        return unless version_was.nil? || version.nil?

        errors.add(:version, _('cannot be changed')) if version_changed?
      end
    end
  end
end
