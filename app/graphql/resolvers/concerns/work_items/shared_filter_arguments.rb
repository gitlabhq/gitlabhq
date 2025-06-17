# frozen_string_literal: true

module WorkItems
  module SharedFilterArguments
    extend ActiveSupport::Concern
    extend Gitlab::Utils::Override

    included do
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
        description: 'Usernames of users assigned to the work item.'
      argument :assignee_wildcard_id, ::Types::AssigneeWildcardIdEnum,
        required: false,
        description: 'Filter by assignee wildcard. Incompatible with `assigneeUsernames`.'
      argument :label_name, [GraphQL::Types::String],
        required: false,
        description: 'Labels applied to the work item.'
      argument :milestone_title, [GraphQL::Types::String],
        required: false,
        description: 'Milestone applied to the work item.'
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
        description: 'List of IIDs of work items. For example, `["1", "2"]`.'
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

      argument :parent_ids, [::Types::GlobalIDType[::WorkItem]],
        description: 'Filter work items by global IDs of their parent items (maximum is 100 items).',
        required: false,
        prepare: ->(global_ids, _ctx) { GitlabSchema.parse_gids(global_ids, expected_type: ::WorkItem).map(&:model_id) }

      argument :release_tag, [GraphQL::Types::String],
        required: false,
        description: "Release tag associated with the work item's milestone. Ignored when parent is a group."
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
    end

    MAX_IDS_LIMIT = 100

    def resolve(**args)
      validate_field_limits(args, :parent_ids, :release_tag)
      validate_field_limits(args[:not], :release_tag) if args[:not].present?

      super
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

      rewrite_param_name(params, :parent_ids, :work_item_parent_ids)
      rewrite_param_name(params, :release_tag_wildcard_id, :release_tag)

      params
    end

    def rewrite_param_name(params, old_name, new_name)
      params[new_name] = params.delete(old_name) if params && params[old_name].present?
    end

    def validate_field_limits(params, *fields)
      return unless params

      fields.each do |field|
        if Array(params[field]).size > MAX_IDS_LIMIT
          raise GraphQL::ExecutionError,
            "You can only provide up to #{MAX_IDS_LIMIT} #{field.to_s.camelize(:lower)} at once."
        end
      end
    end
  end
end
