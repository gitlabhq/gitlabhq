# frozen_string_literal: true

module Types
  module WorkItems
    module SavedViews
      class NegatedFilterInputType < BaseInputObject
        graphql_name 'WorkItemSavedViewNegatedFilterInput'

        argument :assignee_usernames,
          [GraphQL::Types::String],
          required: false,
          validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
          description: "Filter value for not assignee username filter. " \
            "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} usernames)."
        argument :author_username,
          [GraphQL::Types::String],
          required: false,
          validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
          description: "Filter value for not author username filter. " \
            "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} usernames)."
        argument :label_name,
          [GraphQL::Types::String],
          required: false,
          validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
          description: "Filter value for not label name filter. " \
            "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} labels)."
        argument :milestone_title,
          [GraphQL::Types::String],
          required: false,
          validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
          description: "Filter value for not milestone title filter." \
            "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} milestones)."
        argument :milestone_wildcard_id,
          ::Types::NegatedMilestoneWildcardIdEnum,
          required: false,
          description: 'Filter value for not milestone wildcard id filter.'
        argument :my_reaction_emoji,
          GraphQL::Types::String,
          required: false,
          description: 'Filter value for not my reaction emoji filter.'
        argument :parent_ids, [::Types::GlobalIDType[::WorkItem]],
          description: "Filter work items by global IDs who don't belong to parent items " \
            "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} IDs).",
          required: false,
          validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
          prepare: ->(global_ids, _ctx) {
            GitlabSchema.parse_gids(global_ids, expected_type: ::WorkItem).map(&:model_id)
          }
        argument :release_tag,
          [GraphQL::Types::String],
          required: false,
          validates: { length: { maximum: ::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
          description: "File value for not release tag filter. " \
            "(maximum is #{::WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} tags)."
        argument :types,
          [::Types::IssueTypeEnum],
          as: :issue_types,
          description: 'Filter value for not types filter.',
          required: false

        validates mutually_exclusive: [:milestone_title, :milestone_wildcard_id]
      end
    end
  end
end

Types::WorkItems::SavedViews::NegatedFilterInputType.prepend_mod
