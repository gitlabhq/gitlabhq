# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::TypeType, feature_category: :team_planning do
  include GraphqlHelpers

  let(:fields) do
    fields = %i[id icon_name name widget_definitions supported_conversion_types unavailable_widgets_on_conversion
      supports_roadmap_view use_issue_view can_promote_to_objective show_project_selector supports_move_action
      is_service_desk is_incident_management is_configurable can_user_create_items visible_in_settings
      archived is_group_work_item_type enabled is_filterable_list_view is_filterable_board_view]

    fields += %i[enabled_by_default_for_new_namespaces] if Gitlab.ee?

    fields
  end

  specify { expect(described_class.graphql_name).to eq('WorkItemType') }

  specify { expect(described_class).to have_graphql_fields(fields) }

  specify { expect(described_class).to require_graphql_authorizations(:read_work_item_type) }

  describe 'unavailable_widgets_on_conversion field' do
    it 'has the correct arguments' do
      field = described_class.fields['unavailableWidgetsOnConversion']

      expect(field).to be_present
      expect(field.arguments.keys).to contain_exactly('target')

      target_arg = field.arguments['target']

      expect(target_arg.type.to_type_signature).to eq('WorkItemsTypeID!')
    end
  end

  describe 'use_issue_view field' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    let(:ticket_type) { build(:work_item_system_defined_type, :ticket) }

    subject(:use_issue_view) do
      resolve_field(:use_issue_view, ticket_type, current_user: nil, ctx: { resource_parent: project })
    end

    it { is_expected.to be false }

    context 'when work_item_ticket_migration feature flag is disabled' do
      before do
        stub_feature_flags(work_item_ticket_migration: false)
      end

      it { is_expected.to be true }
    end
  end

  describe '.authorization_scopes' do
    it 'allows ai_workflows scope token' do
      expect(described_class.authorization_scopes).to include(:ai_workflows)
    end
  end

  describe 'fields with :ai_workflows scope' do
    %w[id name].each do |field_name|
      it "includes :ai_workflows scope for the #{field_name} field" do
        expect(described_class.fields[field_name]).to include_graphql_scopes(:ai_workflows)
      end
    end
  end
end
