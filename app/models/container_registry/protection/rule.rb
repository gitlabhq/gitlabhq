# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class Rule < ApplicationRecord
      enum delete_protected_up_to_access_level:
             Gitlab::Access.sym_options_with_owner.slice(:maintainer, :owner, :developer),
        _prefix: :delete_protected_up_to
      enum push_protected_up_to_access_level:
             Gitlab::Access.sym_options_with_owner.slice(:maintainer, :owner, :developer),
        _prefix: :push_protected_up_to

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
      validates :delete_protected_up_to_access_level, presence: true
      validates :push_protected_up_to_access_level, presence: true

      validate :path_pattern_starts_with_project_full_path, if: :repository_path_pattern_changed?

      scope :for_repository_path, ->(repository_path) do
        return none if repository_path.blank?

        where(
          ":repository_path ILIKE #{::Gitlab::SQL::Glob.to_like('repository_path_pattern')}",
          repository_path: repository_path
        )
      end

      def self.for_push_exists?(access_level:, repository_path:)
        return false if access_level.blank? || repository_path.blank?

        where(push_protected_up_to_access_level: access_level..)
          .for_repository_path(repository_path)
          .exists?
      end

      def path_pattern_starts_with_project_full_path
        return if repository_path_pattern.downcase.starts_with?(project.full_path.downcase)

        errors.add(:repository_path_pattern, :does_not_start_with_project_full_path)
      end
    end
  end
end
