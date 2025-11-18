# frozen_string_literal: true

module Packages
  module Protection
    class Rule < ApplicationRecord
      before_save :ensure_pattern_type_and_target_field

      NPM_PACKAGE_NAME_FORMAT = {
        with: Gitlab::Regex::Packages::Protection::Rules.protection_rules_npm_package_name_pattern_regex,
        message: ->(_object, _data) { _('should be a valid NPM package name with optional wildcard characters.') }
      }.freeze
      PYPI_PACKAGE_NAME_FORMAT = {
        with: Gitlab::Regex::Packages::Protection::Rules.protection_rules_pypi_package_name_pattern_regex,
        message: ->(_object, _data) { _('should be a valid PyPI package name with optional wildcard characters.') }
      }.freeze

      enum :package_type, Packages::Package.package_types.slice(:conan, :generic, :helm, :maven, :npm, :nuget, :pypi)
      enum :minimum_access_level_for_delete, Gitlab::Access.sym_options_with_admin.slice(:owner, :admin),
        prefix: :minimum_access_level_for_delete
      enum :minimum_access_level_for_push, Gitlab::Access.sym_options_with_admin.slice(:maintainer, :owner, :admin),
        prefix: :minimum_access_level_for_push
      enum :pattern_type, { wildcard: 0 }, prefix: :pattern_type
      enum :target_field, { package_name: 0 }, prefix: :target_field

      belongs_to :project, inverse_of: :package_protection_rules

      validates :package_name_pattern, presence: true, uniqueness: { scope: [:project_id, :package_type] },
        length: { maximum: 255 }

      validates :package_type, presence: true
      validates :pattern, allow_blank: true, length: { maximum: 255 }

      # npm specific validations
      validates :package_name_pattern, format: NPM_PACKAGE_NAME_FORMAT, if: :npm?
      validates :pattern, format: NPM_PACKAGE_NAME_FORMAT, allow_blank: true, if: -> {
        npm? && target_field_package_name? && pattern_type_wildcard?
      }

      # pypi specific validations
      validates :package_name_pattern, format: PYPI_PACKAGE_NAME_FORMAT, if: :pypi?
      validates :pattern, format: PYPI_PACKAGE_NAME_FORMAT, allow_blank: true, if: -> {
        pypi? && target_field_package_name? && pattern_type_wildcard?
      }

      validate :at_least_one_minimum_access_level_must_be_present

      scope :for_package_name, ->(package_name) do
        return none if package_name.blank?

        where(
          ":package_name ILIKE #{::Gitlab::SQL::Glob.to_like('package_name_pattern')}",
          package_name: package_name
        )
      end

      scope :for_package_type, ->(package_type) { where(package_type: package_type) }

      def self.for_delete_exists?(access_level:, package_name:, package_type:)
        for_action_exists?(action: :delete, access_level: access_level, package_name: package_name,
          package_type: package_type)
      end

      def self.for_action_exists?(action:, access_level:, package_name:, package_type:)
        return false if [access_level, package_name, package_type].any?(&:blank?)

        minimum_access_level_column = "minimum_access_level_for_#{action}"

        for_package_type(package_type)
          .where(":access_level < #{minimum_access_level_column}", access_level: access_level)
          .for_package_name(package_name)
          .exists?
      end

      ##
      # Accepts a list of projects and packages and returns a result set
      # indicating whether the package name is protected.
      #
      # @param [Array<Array>] projects_and_packages an array of arrays where each sub-array contains
      # the project id (bigint), the package name (string) and the package type (smallint).
      # @return [ActiveRecord::Result] a result set indicating whether each project, package name and package type
      # is protected.
      #
      # Example:
      #   Packages::Protection::Rule.for_push_exists_for_projects_and_packages([
      #     [1, '@my_group/my_project_1/package_1', 2],
      #     [1, '@my_group/my_project_1/package_2', 2],
      #     [2, '@my_group/my_project_2/package_1', 3],
      #     ...
      #   ])
      #
      #   [
      #     {'project_id' => 1, 'package_name' => '@my_group/my_project_1/package_1', 'package_type' => 2,
      #      'protected' => true},
      #     {'project_id' => 1, 'package_name' => '@my_group/my_project_1/package_2', 'package_type' => 2,
      #      'protected' => false},
      #     {'project_id' => 2, 'package_name' => '@my_group/my_project_2/package_1', 'package_type' => 3,
      #      'protected' => true},
      #     ...
      #   ]
      #
      def self.for_push_exists_for_projects_and_packages(projects_and_packages)
        return none if projects_and_packages.blank?

        project_ids, package_names, package_types = projects_and_packages.transpose

        cte_query_sql = <<~SQL
          unnest(
            ARRAY[:project_ids]::bigint[],
            ARRAY[:package_names]::text[],
            ARRAY[:package_types]::smallint[]
          ) AS projects_and_packages(project_id, package_name, package_type)
        SQL

        cte_query =
          select('*').from(sanitize_sql_array(
            [cte_query_sql, { project_ids: project_ids, package_names: package_names, package_types: package_types }]
          ))

        cte_name = :projects_and_packages_cte
        cte = Gitlab::SQL::CTE.new(cte_name, cte_query)

        rules_cte_project_id = "#{cte_name}.#{connection.quote_column_name('project_id')}"
        rules_cte_package_name = "#{cte_name}.#{connection.quote_column_name('package_name')}"
        rules_cte_package_type = "#{cte_name}.#{connection.quote_column_name('package_type')}"

        protection_rule_exsits_subquery = select(1)
          .where("#{rules_cte_project_id} = project_id")
          .where(arel_table[:package_type].eq(Arel.sql(rules_cte_package_type)))
          .where("#{rules_cte_package_name} ILIKE #{::Gitlab::SQL::Glob.to_like('package_name_pattern')}")

        query = select(
          rules_cte_project_id,
          rules_cte_package_type,
          rules_cte_package_name,
          sanitize_sql_array(['EXISTS(?) AS protected', protection_rule_exsits_subquery])
        ).from(Arel.sql(cte_name.to_s))

        connection.exec_query(query.with(cte.to_arel).to_sql)
      end

      def at_least_one_minimum_access_level_must_be_present
        return unless minimum_access_level_for_delete.blank? && minimum_access_level_for_push.blank?

        errors.add(:base, _('A rule must have at least a minimum access role for push or delete.'))
      end

      def ensure_pattern_type_and_target_field
        self.pattern_type ||= Packages::Protection::Rule.pattern_types[:wildcard]
        self.target_field ||= Packages::Protection::Rule.target_fields[:package_name]
      end
    end
  end
end
