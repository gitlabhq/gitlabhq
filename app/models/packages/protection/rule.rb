# frozen_string_literal: true

module Packages
  module Protection
    class Rule < ApplicationRecord
      include IgnorableColumns

      ignore_column :push_protected_up_to_access_level, remove_with: '17.3', remove_after: '2024-07-22'

      enum package_type: Packages::Package.package_types.slice(:npm)
      enum minimum_access_level_for_push:
          Gitlab::Access.sym_options_with_admin.slice(:maintainer, :owner, :admin),
        _prefix: :minimum_access_level_for_push

      belongs_to :project, inverse_of: :package_protection_rules

      validates :package_name_pattern, presence: true, uniqueness: { scope: [:project_id, :package_type] },
        length: { maximum: 255 }
      validates :package_name_pattern,
        format: {
          with: Gitlab::Regex::Packages::Protection::Rules.protection_rules_npm_package_name_pattern_regex,
          message: ->(_object, _data) { _('should be a valid NPM package name with optional wildcard characters.') }
        },
        if: :npm?
      validates :package_type, presence: true
      validates :minimum_access_level_for_push, presence: true

      scope :for_package_name, ->(package_name) do
        return none if package_name.blank?

        where(
          ":package_name ILIKE #{::Gitlab::SQL::Glob.to_like('package_name_pattern')}",
          package_name: package_name
        )
      end

      def self.for_push_exists?(access_level:, package_name:, package_type:)
        return false if [access_level, package_name, package_type].any?(&:blank?)

        where(package_type: package_type)
          .where(':access_level < minimum_access_level_for_push', access_level: access_level)
          .for_package_name(package_name)
          .exists?
      end
    end
  end
end
