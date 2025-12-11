# frozen_string_literal: true

module Types
  module WorkItems
    module SavedViews
      class FilterInputType < BaseInputObject
        graphql_name 'WorkItemSavedViewFilterInput'

        argument :assignee_usernames,
          [GraphQL::Types::String],
          required: false,
          validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
          description: "Filter values for assignee usernames filter" \
            "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} usernames)."
        argument :assignee_wildcard_id,
          ::Types::AssigneeWildcardIdEnum,
          required: false,
          description: 'Filter values for assignee wildcard id filter. Incompatible with `assigneeUsernames`.'
        argument :author_username,
          GraphQL::Types::String,
          required: false,
          description: 'Filter value for author username filter.'
        argument :closed_after,
          ::Types::TimeType,
          required: false,
          description: 'Filter value for closed after filter.'
        argument :closed_before,
          ::Types::TimeType,
          required: false,
          description: 'Filter value for closed before filter.'
        argument :confidential,
          GraphQL::Types::Boolean,
          required: false,
          description: 'Filter value for confidential filter.'
        argument :created_after,
          ::Types::TimeType,
          required: false,
          description: 'Filter value for created after filter.'
        argument :created_before,
          ::Types::TimeType,
          required: false,
          description: 'Filter value for created before filter.'
        argument :crm_contact_id, GraphQL::Types::String,
          required: false,
          description: 'Filter value for crm contact id filter.'
        argument :crm_organization_id, GraphQL::Types::String,
          required: false,
          description: 'Filter value for crm organization id filter.'
        argument :due_after,
          ::Types::TimeType,
          required: false,
          description: 'Filter value for due after filter.'
        argument :due_before,
          ::Types::TimeType,
          required: false,
          description: 'Filter value for due before filter.'
        argument :exclude_group_work_items,
          GraphQL::Types::Boolean,
          required: false,
          description: 'Filter value for exclude group work items filter.'
        argument :exclude_projects,
          GraphQL::Types::Boolean,
          required: false,
          description: 'Filter value for exclude projects filter.'
        argument :full_path,
          GraphQL::Types::ID,
          required: false,
          description: "Filter value for full path filter."
        argument :hierarchy_filters,
          ::Types::WorkItems::HierarchyFilterInputType,
          description: 'Filter value for hierarchy filter.',
          required: false
        argument :iid,
          GraphQL::Types::String,
          required: false,
          description: 'Filter value for IID filter.'
        argument :in,
          [Types::IssuableSearchableFieldEnum],
          required: false,
          description: '"Filter value for in filter.'
        argument :include_descendant_work_items,
          GraphQL::Types::Boolean,
          description: 'Filter value for include descendant work items filter.',
          required: false
        argument :include_descendants,
          GraphQL::Types::Boolean,
          required: false,
          description: 'Filter value for include descendants filter.'
        argument :label_name,
          [GraphQL::Types::String],
          required: false,
          validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
          description: "Filter value for label name filter. " \
            "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} labels)."
        argument :milestone_title, [GraphQL::Types::String],
          required: false,
          validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
          description: "Filter value for milestone title filter. " \
            "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} milestones)."
        argument :milestone_wildcard_id,
          ::Types::MilestoneWildcardIdEnum,
          required: false,
          description: 'Filter value for milestone wildcard id filter. Incompatible with `milestoneTitle`.'
        argument :my_reaction_emoji,
          GraphQL::Types::String,
          required: false,
          description: 'Filter value for my reaction emoji filter.'
        argument :not,
          ::Types::WorkItems::SavedViews::NegatedFilterInputType,
          description: 'Filter value for not filter.',
          required: false,
          prepare: ->(value, _ctx) {
            value.to_h
          }
        argument :or,
          ::Types::WorkItems::SavedViews::UnionedFilterInputType,
          description: 'Filter values for or filter.',
          required: false,
          prepare: ->(value, _ctx) {
            value.to_h
          }
        argument :release_tag,
          [GraphQL::Types::String],
          required: false,
          validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
          description: "Filter value for release tag filter (maximum is " \
            "#{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} tags)."
        argument :release_tag_wildcard_id,
          ::Types::ReleaseTagWildcardIdEnum,
          required: false,
          description: 'Filter value for release tag wildcard id filter.'
        argument :search,
          GraphQL::Types::String,
          required: false,
          description: 'Filter value for search filter.'
        argument :state,
          ::Types::IssuableStateEnum,
          required: false,
          description: 'Filter value for state filter.',
          prepare: ->(state, _ctx) {
            return state unless state == 'locked'

            raise Gitlab::Graphql::Errors::ArgumentError, ::Types::IssuableStateEnum::INVALID_LOCKED_MESSAGE
          }
        argument :subscribed,
          ::Types::Issuables::SubscriptionStatusEnum,
          description: 'Filter value for subscribed filter.',
          required: false
        argument :types,
          [::Types::IssueTypeEnum],
          as: :issue_types,
          description: 'Filter value for types filter.',
          required: false
        argument :updated_after,
          ::Types::TimeType,
          required: false,
          description: 'Filter value for updated after filter.'
        argument :updated_before,
          ::Types::TimeType,
          required: false,
          description: 'Filter value for updated before filter.'

        validates mutually_exclusive: [:assignee_usernames, :assignee_wildcard_id]
        validates mutually_exclusive: [:milestone_title, :milestone_wildcard_id]
        validates mutually_exclusive: [:release_tag, :release_tag_wildcard_id]

        validates mutually_exclusive: [:hierarchy_filters, :include_descendant_work_items]
      end
    end
  end
end

Types::WorkItems::SavedViews::FilterInputType.prepend_mod
