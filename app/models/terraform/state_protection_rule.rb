# frozen_string_literal: true

module Terraform
  class StateProtectionRule < ApplicationRecord
    belongs_to :project, inverse_of: :terraform_state_protection_rules

    enum :minimum_access_level_for_write, {
      developer: Gitlab::Access::DEVELOPER,
      maintainer: Gitlab::Access::MAINTAINER,
      owner: Gitlab::Access::OWNER,
      admin: Gitlab::Access::ADMIN
    }, prefix: true

    enum :allowed_from, {
      anywhere: 0,
      ci_only: 1,
      ci_on_protected_branch_only: 2
    }, prefix: true

    validates :state_name, presence: true, length: { maximum: 255 },
      uniqueness: { scope: :project_id }
    validates :minimum_access_level_for_write, presence: true
    validates :allowed_from, presence: true

    def self.exists_for_projects_and_state_names(projects_and_state_names)
      return none if projects_and_state_names.blank?

      project_ids, state_names = projects_and_state_names.transpose

      cte_query =
        select('*').from(
          sanitize_sql_array([
            'unnest(ARRAY[:project_ids]::bigint[], ARRAY[:state_names]::text[]) ' \
              'AS projects_and_state_names(project_id, state_name)',
            { project_ids: project_ids, state_names: state_names }
          ])
        )

      cte_name = :projects_and_state_names_cte
      cte = Gitlab::SQL::CTE.new(cte_name, cte_query)

      rules_cte_project_id = "#{cte_name}.#{adapter_class.quote_column_name('project_id')}"
      rules_cte_state_name = "#{cte_name}.#{adapter_class.quote_column_name('state_name')}"

      protection_rule_exists_subquery =
        select(1)
          .where(arel_table[:project_id].eq(Arel.sql(rules_cte_project_id)))
          .where(arel_table[:state_name].eq(Arel.sql(rules_cte_state_name)))

      query = select(
        rules_cte_project_id,
        rules_cte_state_name,
        sanitize_sql_array(['EXISTS(?) AS protected', protection_rule_exists_subquery])
      ).from(Arel.sql(cte_name.to_s))

      connection.exec_query(query.with(cte.to_arel).to_sql)
    end
  end
end
