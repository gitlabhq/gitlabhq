# frozen_string_literal: true

module Projects
  module BranchRules
    class SquashOption < ApplicationRecord
      include ::Projects::SquashOption

      belongs_to :protected_branch, optional: false
      belongs_to :project, optional: false

      validates :protected_branch, uniqueness: true

      validate :validate_protected_branch_not_wildcard
      validate :validate_protected_branch_belongs_to_project, if: -> { protected_branch_changed? || project_changed? }

      def branch_rule
        ::Projects::BranchRule.new(project, protected_branch)
      end

      private

      def validate_protected_branch_not_wildcard
        return unless protected_branch&.wildcard?

        errors.add(:protected_branch, _('cannot be used with wildcard branch rules. Use an exact branch name.'))
      end

      def validate_protected_branch_belongs_to_project
        return unless protected_branch && project
        return if protected_branch.project_id == project.id

        errors.add(:protected_branch, _('must belong to project'))
      end
    end
  end
end
