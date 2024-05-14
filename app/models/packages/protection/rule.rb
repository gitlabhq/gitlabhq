# frozen_string_literal: true

module Packages
  module Protection
    class Rule < ApplicationRecord
      enum package_type: Packages::Package.package_types.slice(:npm)
      enum push_protected_up_to_access_level:
             Gitlab::Access.sym_options_with_owner.slice(:developer, :maintainer, :owner),
        _prefix: :push_protected_up_to

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
      validates :push_protected_up_to_access_level, presence: true

      scope :for_package_name, ->(package_name) do
        return none if package_name.blank?

        where(
          ":package_name ILIKE #{::Gitlab::SQL::Glob.to_like('package_name_pattern')}",
          package_name: package_name
        )
      end

      def self.for_push_exists?(access_level:, package_name:, package_type:)
        return false if [access_level, package_name, package_type].any?(&:blank?)

        where(package_type: package_type, push_protected_up_to_access_level: access_level..)
          .for_package_name(package_name)
          .exists?
      end
    end
  end
end
