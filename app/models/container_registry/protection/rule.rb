# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class Rule < ApplicationRecord
      enum minimum_access_level_for_delete:
             Gitlab::Access.sym_options_with_admin.slice(:maintainer, :owner, :admin),
        _prefix: :minimum_access_level_for_delete
      enum minimum_access_level_for_push:
             Gitlab::Access.sym_options_with_admin.slice(:maintainer, :owner, :admin),
        _prefix: :minimum_access_level_for_push

      belongs_to :project, inverse_of: :container_registry_protection_rules

      validates :repository_path_pattern, presence: true, uniqueness: { scope: :project_id }, length: { maximum: 255 }
      validates :repository_path_pattern,
        format: {
          with:
            Gitlab::Regex::ContainerRegistry::Protection::Rules
              .protection_rules_container_repository_path_pattern_regex,
          message:
            ->(_object, _data) { _('should be a valid container repository path with optional wildcard characters.') }
        }

      validate :path_pattern_starts_with_project_full_path, if: :repository_path_pattern_changed?
      validate :at_least_one_minimum_access_level_must_be_present

      scope :for_repository_path, ->(repository_path) do
        return none if repository_path.blank?

        where(
          ":repository_path ILIKE #{::Gitlab::SQL::Glob.to_like('repository_path_pattern')}",
          repository_path: repository_path
        )
      end

      def self.for_push_exists?(access_level:, repository_path:)
        return false if access_level.blank? || repository_path.blank?

        where(':access_level < minimum_access_level_for_push', access_level: access_level)
          .for_repository_path(repository_path)
          .exists?
      end

      ##
      # Accepts a list of projects and repository paths and returns a result set
      # indicating whether the repository path is protected.
      #
      # @param [Array<Array>] projects_repository_paths an array of arrays where each sub-array contains a project id
      # and a repository path.
      # @return [ActiveRecord::Result] a result set indicating whether each project and repository path is protected.
      #
      # Example:
      #   ContainerRegistry::Protection::Rule.for_push_exists_for_projects_and_repository_paths([
      #     [1, '/my_group/my_project_1/image_1'],
      #     [1, '/my_group/my_project_1/image_2'],
      #     [2, '/my_group/my_project_2/image_1'],
      #     ...
      #   ])
      #
      #   [
      #     {'project_id' => 1, 'repository_path_pattern' => '/my_group/my_project_1/image_1', 'protected' => true},
      #     {'project_id' => 1, 'repository_path_pattern' => '/my_group/my_project_1/image_2', 'protected' => false},
      #     {'project_id' => 2, 'repository_path_pattern' => '/my_group/my_project_2/image_1', 'protected' => true},
      #     ...
      #   ]
      #
      def self.for_push_exists_for_projects_and_repository_paths(projects_repository_paths)
        return none if projects_repository_paths.blank?

        project_ids, repository_paths = projects_repository_paths.transpose

        cte_query =
          select('*').from(
            sanitize_sql_array([
              'unnest(ARRAY[:project_ids]::bigint[], ARRAY[:repository_paths]::text[]) ' \
                'AS projects_repository_paths(project_id, repository_path)',
              { project_ids: project_ids, repository_paths: repository_paths }
            ])
          )

        cte_name = :projects_repository_paths_cte
        cte = Gitlab::SQL::CTE.new(cte_name, cte_query)

        rules_cte_project_id = "#{cte_name}.#{connection.quote_column_name('project_id')}"
        rules_cte_repository_path = "#{cte_name}.#{connection.quote_column_name('repository_path')}"

        protection_rule_exsits_subquery =
          select(1)
            .where("#{rules_cte_project_id} = project_id")
            .where("#{rules_cte_repository_path} ILIKE #{::Gitlab::SQL::Glob.to_like('repository_path_pattern')}")

        query = select(
          rules_cte_project_id,
          rules_cte_repository_path,
          sanitize_sql_array(['EXISTS(?) AS protected', protection_rule_exsits_subquery])
        ).from(Arel.sql(cte_name.to_s))

        connection.exec_query(query.with(cte.to_arel).to_sql)
      end

      private

      def path_pattern_starts_with_project_full_path
        return if repository_path_pattern.downcase.starts_with?(project.full_path.downcase)

        errors.add(:repository_path_pattern, :does_not_start_with_project_full_path)
      end

      def at_least_one_minimum_access_level_must_be_present
        return unless minimum_access_level_for_delete.blank? && minimum_access_level_for_push.blank?

        errors.add(:base, _('A rule must have at least a minimum access role for push or delete.'))
      end
    end
  end
end
