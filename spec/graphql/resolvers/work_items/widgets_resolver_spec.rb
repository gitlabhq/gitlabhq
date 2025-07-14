# frozen_string_literal: true

require "spec_helper"

RSpec.describe Resolvers::WorkItems::WidgetsResolver, feature_category: :team_planning do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:epic_type) { create(:work_item_type, :epic, namespace: group) }
  let_it_be(:issue_type) { create(:work_item_type, :issue, namespace: group) }
  let_it_be(:task_type) { create(:work_item_type, :task, namespace: group) }

  def resolve_items(args = {}, context = { current_user: current_user })
    resolve(described_class, args: args, ctx: context, arg_style: :internal, obj: group)
  end

  it 'when passing more work items than limit' do
    expect_graphql_error_to_be_created(
      Gitlab::Graphql::Errors::ArgumentError,
      'No more than 100 work items can be loaded at the same time'
    ) do
      resolve_items(ids: (0..105).to_a.map { |id| "gid://gitlab/WorkItem/#{id}" })
    end
  end

  it 'when ids do not exist' do
    expect(resolve_items(ids: [GlobalID.parse("gid://gitlab/WorkItem/-1")]))
      .to be_empty
  end

  where(:union, :work_item_types, :widgets) do
    [
      [
        false,
        lazy { [epic_type] },
        %w[
          ASSIGNEES
          AWARD_EMOJI
          CURRENT_USER_TODOS
          DESCRIPTION
          HIERARCHY
          LABELS
          LINKED_ITEMS
          MILESTONE
          NOTES
          NOTIFICATIONS
          PARTICIPANTS
          START_AND_DUE_DATE
          TIME_TRACKING
        ]
      ],
      [
        false,
        lazy { [issue_type] },
        %w[
          ASSIGNEES
          AWARD_EMOJI
          CRM_CONTACTS
          CURRENT_USER_TODOS
          DESCRIPTION
          DESIGNS
          DEVELOPMENT
          EMAIL_PARTICIPANTS
          ERROR_TRACKING
          HIERARCHY
          LABELS
          LINKED_ITEMS
          LINKED_RESOURCES
          MILESTONE
          NOTES
          NOTIFICATIONS
          PARTICIPANTS
          START_AND_DUE_DATE
          TIME_TRACKING
        ]
      ],
      [
        false,
        lazy { [task_type] },
        %w[
          ASSIGNEES
          AWARD_EMOJI
          CRM_CONTACTS
          CURRENT_USER_TODOS
          DESCRIPTION
          DEVELOPMENT
          HIERARCHY
          LABELS
          LINKED_ITEMS
          LINKED_RESOURCES
          MILESTONE
          NOTES
          NOTIFICATIONS
          PARTICIPANTS
          START_AND_DUE_DATE
          TIME_TRACKING
        ]
      ],
      [
        false,
        lazy { [epic_type, issue_type] },
        %w[
          ASSIGNEES
          AWARD_EMOJI
          CURRENT_USER_TODOS
          DESCRIPTION
          HIERARCHY
          LABELS
          LINKED_ITEMS
          MILESTONE
          NOTES
          NOTIFICATIONS
          PARTICIPANTS
          START_AND_DUE_DATE
          TIME_TRACKING
        ]
      ],
      [
        false,
        lazy { [epic_type, issue_type, task_type] },
        %w[
          ASSIGNEES
          AWARD_EMOJI
          CURRENT_USER_TODOS
          DESCRIPTION
          HIERARCHY
          LABELS
          LINKED_ITEMS
          MILESTONE
          NOTES
          NOTIFICATIONS
          PARTICIPANTS
          START_AND_DUE_DATE
          TIME_TRACKING
        ]
      ],
      [
        true,
        lazy { [epic_type] },
        %w[
          ASSIGNEES
          AWARD_EMOJI
          CURRENT_USER_TODOS
          DESCRIPTION
          HIERARCHY
          LABELS
          LINKED_ITEMS
          MILESTONE
          NOTES
          NOTIFICATIONS
          PARTICIPANTS
          START_AND_DUE_DATE
          TIME_TRACKING
        ]
      ],
      [
        true,
        lazy { [epic_type, issue_type] },
        %w[
          ASSIGNEES
          AWARD_EMOJI
          CRM_CONTACTS
          CURRENT_USER_TODOS
          DESCRIPTION
          DESIGNS
          DEVELOPMENT
          EMAIL_PARTICIPANTS
          ERROR_TRACKING
          HIERARCHY
          LABELS
          LINKED_ITEMS
          LINKED_RESOURCES
          MILESTONE
          NOTES
          NOTIFICATIONS
          PARTICIPANTS
          START_AND_DUE_DATE
          TIME_TRACKING
        ]
      ],
      [
        true,
        lazy { [epic_type, issue_type, task_type] },
        %w[
          ASSIGNEES
          AWARD_EMOJI
          CRM_CONTACTS
          CURRENT_USER_TODOS
          DESCRIPTION
          DESIGNS
          DEVELOPMENT
          EMAIL_PARTICIPANTS
          ERROR_TRACKING
          HIERARCHY
          LABELS
          LINKED_ITEMS
          LINKED_RESOURCES
          MILESTONE
          NOTES
          NOTIFICATIONS
          PARTICIPANTS
          START_AND_DUE_DATE
          TIME_TRACKING
        ]
      ]
    ]
  end

  with_them do
    it "list unique widgets for the given work items" do
      expect(
        resolve_items(ids: work_item_types.map(&:to_gid), union: union)
      ).to match_array(widgets)
    end
  end
end
