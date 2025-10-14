# frozen_string_literal: true

module Packages
  module Composer
    class Package < ::Packages::Package
      self.table_name = :packages_composer_packages
      self.inheritance_column = nil # rubocop:disable Database/AvoidInheritanceColumn -- suppress single table inheritance

      validate :valid_composer_global_name
      validates :version, format: { with: Gitlab::Regex.semver_regex, message: Gitlab::Regex.semver_regex_message },
        unless: -> { Gitlab::Regex.composer_dev_version_regex.match(version.to_s) }
      validates :name,
        uniqueness: {
          scope: %i[project_id version],
          conditions: -> { not_pending_destruction }
        },
        unless: -> { pending_destruction? }
      validates :name, format: { with: Gitlab::Regex.package_name_regex }

      scope :with_composer_target, ->(target) { where(target_sha: target) }

      # The class inherits the package_type enum from the parent class.
      # However, the database table doesn't have package_type column.
      # In order to conform the enum rules, we define an attribute.
      # Without doing that, the error will be raised.
      attribute :package_type, :integer, default: 6

      # In order to make sure all package_type usage patterns work correctly.
      enum :package_type, { composer: 6 }

      private

      def valid_composer_global_name
        return unless self.class.not_pending_destruction
                                .with_name(name)
                                .where.not(project_id: project_id)
                                .exists?

        errors.add(:name, 'is already taken by another project')
      end
    end
  end
end
