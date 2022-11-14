# frozen_string_literal: true

module Types
  module Projects
    class BranchRuleType < BaseObject
      graphql_name 'BranchRule'
      description 'List of branch rules for a project, grouped by branch name.'
      accepts ::ProtectedBranch
      authorize :read_protected_branch

      alias_method :branch_rule, :object

      field :name,
            type: GraphQL::Types::String,
            null: false,
            description: 'Branch name, with wildcards, for the branch rules.'

      field :is_default,
            type: GraphQL::Types::Boolean,
            null: false,
            method: :default_branch?,
            calls_gitaly: true,
            description: "Check if this branch rule protects the project's default branch."

      field :matching_branches_count,
            type: GraphQL::Types::Int,
            null: false,
            calls_gitaly: true,
            description: 'Number of existing branches that match this branch rule.'

      field :branch_protection,
            type: Types::BranchRules::BranchProtectionType,
            null: false,
            description: 'Branch protections configured for this branch rule.',
            method: :itself

      field :created_at,
            Types::TimeType,
            null: false,
            description: 'Timestamp of when the branch rule was created.'

      field :updated_at,
            Types::TimeType,
            null: false,
            description: 'Timestamp of when the branch rule was last updated.'

      def matching_branches_count
        branch_rule.matching(branch_rule.project.repository.branch_names).count
      end
    end
  end
end

Types::Projects::BranchRuleType.prepend_mod
