# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class Rule < ApplicationRecord
      include IgnorableColumns
      ignore_columns %i[push_protected_up_to_access_level delete_protected_up_to_access_level],
        remove_with: '17.2', remove_after: '2024-06-22'

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
