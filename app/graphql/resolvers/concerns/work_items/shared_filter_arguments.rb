# frozen_string_literal: true

module WorkItems
  module SharedFilterArguments
    extend ActiveSupport::Concern
    extend Gitlab::Utils::Override

    MAX_FIELD_LIMIT = 100

    included do
      argument :ids,
        [::Types::GlobalIDType[::WorkItem]],
        required: false,
        validates: { length: { maximum: MAX_FIELD_LIMIT } },
        description: "Filter by global IDs of work items (maximum is #{MAX_FIELD_LIMIT} IDs).",
        prepare: ->(global_ids, _ctx) { GitlabSchema.parse_gids(global_ids, expected_type: ::WorkItem).map(&:model_id) }
      argument :author_username,
        GraphQL::Types::String,
        required: false,
        description: 'Filter work items by author username.'
      argument :confidential,
        GraphQL::Types::Boolean,
        required: false,
        description: 'Filter for confidential work items. If `false`, excludes confidential work items. ' \
          'If `true`, returns only confidential work items.'
      argument :assignee_usernames, [GraphQL::Types::String],
        required: false,
        validates: { length: { maximum: MAX_FIELD_LIMIT } },
        description: "Usernames of users assigned to the work item (maximum is #{MAX_FIELD_LIMIT} usernames)."
      argument :assignee_wildcard_id, ::Types::AssigneeWildcardIdEnum,
        required: false,
        description: 'Filter by assignee wildcard. Incompatible with `assigneeUsernames`.'
      argument :label_name, [GraphQL::Types::String],
        required: false,
        validates: { length: { maximum: MAX_FIELD_LIMIT } },
        description: "Labels applied to the work item (maximum is #{MAX_FIELD_LIMIT} labels)."
      argument :milestone_title, [GraphQL::Types::String],
        required: false,
        validates: { length: { maximum: MAX_FIELD_LIMIT } },
        description: "Milestone applied to the work item (maximum is #{MAX_FIELD_LIMIT} milestones)."
      argument :milestone_wildcard_id, ::Types::MilestoneWildcardIdEnum,
        required: false,
        description: 'Filter by milestone ID wildcard. Incompatible with `milestoneTitle`.'
      argument :my_reaction_emoji, GraphQL::Types::String,
        required: false,
        description: 'Filter by reaction emoji applied by the current user. ' \
          'Wildcard values `NONE` and `ANY` are supported.'
      argument :iids,
        [GraphQL::Types::String],
        required: false,
        validates: { length: { maximum: MAX_FIELD_LIMIT } },
        description: "List of IIDs of work items. For example, `[\"1\", \"2\"]` (maximum is #{MAX_FIELD_LIMIT} IIDs)."
      argument :state,
        ::Types::IssuableStateEnum,
        required: false,
        description: 'Current state of the work item.',
        prepare: ->(state, _ctx) {
          return state unless state == 'locked'

          raise Gitlab::Graphql::Errors::ArgumentError, ::Types::IssuableStateEnum::INVALID_LOCKED_MESSAGE
        }
      argument :types,
        [::Types::IssueTypeEnum],
        as: :issue_types,
        description: 'Filter work items by the given work item types.',
        required: false

      argument :created_before, ::Types::TimeType,
        required: false,
        description: 'Work items created before the timestamp.'
      argument :created_after, ::Types::TimeType,
        required: false,
        description: 'Work items created after the timestamp.'

      argument :updated_before, ::Types::TimeType,
        required: false,
        description: 'Work items updated before the timestamp.'
      argument :updated_after, ::Types::TimeType,
        required: false,
        description: 'Work items updated after the timestamp.'

      argument :due_before, ::Types::TimeType,
        required: false,
        description: 'Work items due before the timestamp.'
      argument :due_after, ::Types::TimeType,
        required: false,
        description: 'Work items due after the timestamp.'

      argument :closed_before, ::Types::TimeType,
        required: false,
        description: 'Work items closed before the date.'
      argument :closed_after, ::Types::TimeType,
        required: false,
        description: 'Work items closed after the date.'

      argument :subscribed, ::Types::Issuables::SubscriptionStatusEnum,
        description: 'Work items the current user is subscribed to.',
        required: false

      argument :not, ::Types::WorkItems::NegatedWorkItemFilterInputType,
        description: 'Negated work item arguments.',
        required: false,
        prepare: ->(value, _ctx) {
          value.to_h
        }
      argument :or, ::Types::WorkItems::UnionedWorkItemFilterInputType,
        description: 'List of arguments with inclusive `OR`.',
        required: false,
        prepare: ->(value, _ctx) {
          value.to_h
        }

      argument :hierarchy_filters, ::Types::WorkItems::HierarchyFilterInputType,
        description: 'Filtering options related to the work item hierarchy.',
        required: false,
        experiment: { milestone: '18.3' }

      argument :parent_ids, [::Types::GlobalIDType[::WorkItem]],
        description: "Filter work items by global IDs of their parent items (maximum is #{MAX_FIELD_LIMIT} IDs).",
        required: false,
        validates: { length: { maximum: MAX_FIELD_LIMIT } },
        prepare: ->(global_ids, _ctx) { GitlabSchema.parse_gids(global_ids, expected_type: ::WorkItem).map(&:model_id) }

      argument :parent_wildcard_id, ::Types::WorkItems::ParentWildcardIdEnum,
        required: false,
        description: 'Filter by parent ID wildcard. Incompatible with parentIds.',
        experiment: { milestone: '18.5' }

      argument :include_descendant_work_items, GraphQL::Types::Boolean,
        description: 'Whether to include work items of descendant parents when filtering by parent_ids.',
        required: false,
        experiment: { milestone: '18.3' }

      argument :release_tag, [GraphQL::Types::String],
        required: false,
        validates: { length: { maximum: MAX_FIELD_LIMIT } },
        description: "Release tag associated with the work item's milestone (maximum is #{MAX_FIELD_LIMIT} tags). " \
          "Ignored when parent is a group."
      argument :release_tag_wildcard_id, ::Types::ReleaseTagWildcardIdEnum,
        required: false,
        description: 'Filter by release tag wildcard.'
      argument :crm_contact_id, GraphQL::Types::String,
        required: false,
        description: 'Filter by ID of CRM contact.'
      argument :crm_organization_id, GraphQL::Types::String,
        required: false,
        description: 'Filter by ID of CRM contact organization.'

      validates mutually_exclusive: [:assignee_usernames, :assignee_wildcard_id]
      validates mutually_exclusive: [:milestone_title, :milestone_wildcard_id]
      validates mutually_exclusive: [:release_tag, :release_tag_wildcard_id]

      validates mutually_exclusive: [:parent_ids, :parent_wildcard_id]
      validates mutually_exclusive: [:hierarchy_filters, :parent_ids]
      validates mutually_exclusive: [:hierarchy_filters, :parent_wildcard_id]
      validates mutually_exclusive: [:hierarchy_filters, :include_descendant_work_items]
    end

    private

    override :prepare_finder_params
    def prepare_finder_params(args)
      params = super

      rewrite_param_name(params, :assignee_usernames, :assignee_username)
      rewrite_param_name(params[:or], :assignee_usernames, :assignee_username)
      rewrite_param_name(params[:not], :assignee_usernames, :assignee_username)
      rewrite_param_name(params, :assignee_wildcard_id, :assignee_id)

      rewrite_param_name(params[:or], :author_usernames, :author_username)
      rewrite_param_name(params[:or], :label_names, :label_name)

      # Must be called before we rewrite the parent_ids param below
      unpack_parent_filtering_args!(params)

      rewrite_param_name(params, :parent_ids, :work_item_parent_ids)
      rewrite_param_name(params[:not], :parent_ids, :work_item_parent_ids)

      rewrite_param_name(params, :release_tag_wildcard_id, :release_tag)

      params
    end

    def rewrite_param_name(params, old_name, new_name)
      params[new_name] = params.delete(old_name) if params && params[old_name].present?
    end

    def unpack_parent_filtering_args!(params)
      return unless params&.dig(:hierarchy_filters)

      wi_hierarchy_filtering = params.delete(:hierarchy_filters).to_h

      params.merge!(
        wi_hierarchy_filtering.slice(:parent_ids, :include_descendant_work_items, :parent_wildcard_id).compact
      )
    end
  end
end
