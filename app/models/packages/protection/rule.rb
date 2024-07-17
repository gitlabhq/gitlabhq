# frozen_string_literal: true

module Packages
  module Protection
    class Rule < ApplicationRecord
      include IgnorableColumns

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

      def self.for_push_exists_for_multiple_packages(package_names:, package_types:, project_id:)
        return none if package_names.blank? || package_types.blank? || project_id.blank?
        return none if package_names.size != package_types.size

        cte_query =
          select('*').from(
            sanitize_sql_array(
              [
                "unnest(ARRAY[:package_names], ARRAY[:package_types]) AS x(package_name, package_type)",
                { package_names: package_names, package_types: package_types }
              ]
            )
          )

        cte_name = :package_names_and_types_cte
        cte = Gitlab::SQL::CTE.new(cte_name, cte_query)

        rules_cte_package_type = "#{cte_name}.#{connection.quote_column_name('package_type')}"
        rules_cte_package_name = "#{cte_name}.#{connection.quote_column_name('package_name')}"

        protection_rule_exsits_subquery = select(1)
          .where(project_id: project_id)
          .where(arel_table[:package_type].eq(Arel.sql(rules_cte_package_type)))
          .where("#{rules_cte_package_name} ILIKE #{::Gitlab::SQL::Glob.to_like('package_name_pattern')}")

        query = select(
          rules_cte_package_type,
          rules_cte_package_name,
          sanitize_sql_array(['EXISTS(?) AS protected', protection_rule_exsits_subquery])
        ).from(Arel.sql(cte_name.to_s))

        connection.exec_query(query.with(cte.to_arel).to_sql)
      end
    end
  end
end
