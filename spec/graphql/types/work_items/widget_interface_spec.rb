# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::WidgetInterface, feature_category: :team_planning do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  it 'exposes the expected fields' do
    expected_fields = %i[type]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  where(:widget_class, :widget_type_name) do
    WorkItems::Widgets::Description       | Types::WorkItems::Widgets::DescriptionType
    WorkItems::Widgets::Hierarchy         | Types::WorkItems::Widgets::HierarchyType
    WorkItems::Widgets::Assignees         | Types::WorkItems::Widgets::AssigneesType
    WorkItems::Widgets::Labels            | Types::WorkItems::Widgets::LabelsType
    WorkItems::Widgets::Notes             | Types::WorkItems::Widgets::NotesType
    WorkItems::Widgets::Notifications     | Types::WorkItems::Widgets::NotificationsType
    WorkItems::Widgets::CurrentUserTodos  | Types::WorkItems::Widgets::CurrentUserTodosType
    WorkItems::Widgets::AwardEmoji        | Types::WorkItems::Widgets::AwardEmojiType
    WorkItems::Widgets::LinkedItems       | Types::WorkItems::Widgets::LinkedItemsType
    WorkItems::Widgets::LinkedItems       | Types::WorkItems::Widgets::LinkedItemsType
    WorkItems::Widgets::StartAndDueDate   | Types::WorkItems::Widgets::StartAndDueDateType
    WorkItems::Widgets::Milestone         | Types::WorkItems::Widgets::MilestoneType
    WorkItems::Widgets::Participants      | Types::WorkItems::Widgets::ParticipantsType
    WorkItems::Widgets::TimeTracking      | Types::WorkItems::Widgets::TimeTracking::TimeTrackingType
    WorkItems::Widgets::Designs           | Types::WorkItems::Widgets::DesignsType
    WorkItems::Widgets::CrmContacts       | Types::WorkItems::Widgets::CrmContactsType
    WorkItems::Widgets::EmailParticipants | Types::WorkItems::Widgets::EmailParticipantsType
    WorkItems::Widgets::CustomStatus      | Types::WorkItems::Widgets::CustomStatusType
  end

  with_them do
    describe ".resolve_type" do
      it 'knows the correct type for objects' do
        expect(
          described_class.resolve_type(widget_class.new(build(:work_item)), {})
        ).to eq(widget_type_name)
      end

      it 'raises an error for an unknown type' do
        project = build(:project)

        expect { described_class.resolve_type(project, {}) }
          .to raise_error("Unknown GraphQL type for widget #{project}")
      end
    end

    describe '.orphan_types' do
      it 'includes the type' do
        expect(described_class.orphan_types).to include(widget_type_name)
      end
    end
  end
end
