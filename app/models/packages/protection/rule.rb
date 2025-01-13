# frozen_string_literal: true

module Packages
  module Protection
    class Rule < ApplicationRecord
      enum package_type: Packages::Package.package_types.slice(:conan, :npm, :pypi)
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
      validates :package_name_pattern,
        format: {
          with: Gitlab::Regex::Packages::Protection::Rules.protection_rules_pypi_package_name_pattern_regex,
          message: ->(_object, _data) { _('should be a valid PyPI package name with optional wildcard characters.') }
        },
        if: :pypi?
      validates :package_type, presence: true
      validates :minimum_access_level_for_push, presence: true

      scope :for_package_name, ->(package_name) do
        return none if package_name.blank?

        where(
          ":package_name ILIKE #{::Gitlab::SQL::Glob.to_like('package_name_pattern')}",
          package_name: package_name
        )
      end

      scope :for_package_type, ->(package_type) { where(package_type: package_type) }

      def self.for_push_exists?(access_level:, package_name:, package_type:)
        return false if [access_level, package_name, package_type].any?(&:blank?)

        for_package_type(package_type)
          .where(':access_level < minimum_access_level_for_push', access_level: access_level)
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
    end
  end
end
