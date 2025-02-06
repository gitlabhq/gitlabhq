# frozen_string_literal: true

module Types
  module Projects
    class BranchRuleType < BaseObject
      graphql_name 'BranchRule'
      description 'Branch rules configured for a rule target.'
      authorize :read_protected_branch

      alias_method :branch_rule, :object

      field :id, ::Types::GlobalIDType[::Projects::BranchRule],
        description: 'ID of the branch rule.'

      field :name,
        type: GraphQL::Types::String,
        null: false,
        description: 'Name of the branch rule target. Includes wildcards.'

      field :is_default,
        type: GraphQL::Types::Boolean,
        null: false,
        method: :default_branch?,
        calls_gitaly: true,
        description: "Check if this branch rule protects the project's default branch."

      field :is_protected,
        type: GraphQL::Types::Boolean,
        null: false,
        method: :protected?,
        description: "Check if this branch rule protects access for the branch."

      field :matching_branches_count,
        type: GraphQL::Types::Int,
        null: false,
        calls_gitaly: true,
        description: 'Number of existing branches that match this branch rule.'

      field :branch_protection,
        type: Types::BranchRules::BranchProtectionType,
        null: true,
        description: 'Branch protections configured for this branch rule.'

      field :created_at,
        Types::TimeType,
        null: true,
        description: 'Timestamp of when the branch rule was created.'

      field :squash_option,
        type: ::Types::Projects::BranchRules::SquashOptionType,
        null: true,
        description: 'The default behavior for squashing in merge requests. ' \
          'Returns null if `branch_rule_squash_settings` feature flag is disabled.',
        experiment: { milestone: '17.9' }
      field :updated_at,
        Types::TimeType,
        null: true,
        description: 'Timestamp of when the branch rule was last updated.'

      def squash_option
        return unless ::Feature.enabled?(:branch_rule_squash_settings, branch_rule.project)

        branch_rule.squash_option
      end
    end
  end
end

Types::Projects::BranchRuleType.prepend_mod
