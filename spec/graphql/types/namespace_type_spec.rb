# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Namespace'], feature_category: :shared do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('Namespace') }

  specify { expect(described_class.interfaces).to include(Types::TodoableInterface) }

  it 'has the expected fields' do
    expected_fields = %w[
      id name path full_name full_path achievements_path description description_html visibility
      lfs_enabled request_access_enabled projects root_storage_statistics root_namespace shared_runners_setting
      timelog_categories achievements work_item pages_deployments import_source_users work_item_types
      work_items_widgets sidebar work_item_description_templates ci_cd_settings avatar_url link_paths
      metadata licensed_features available_features merge_requests_enabled saved_views subscribed_saved_view_limit
      can_push_initial_commit
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_namespace) }

  describe '.authorization_scopes' do
    it 'allows ai_workflows scope token' do
      expect(described_class.authorization_scopes).to include(:ai_workflows)
    end
  end

  describe 'fields with :ai_workflows scope' do
    %w[id name description fullPath workItem workItems webUrl workItemTypes rootNamespace].each do |field_name|
      it "includes :ai_workflows scope for the #{field_name} field" do
        field = described_class.fields[field_name]
        expect(field.instance_variable_get(:@scopes)).to include(:ai_workflows)
      end
    end
  end

  describe '#can_push_initial_commit' do
    subject { resolve_field(:can_push_initial_commit, group, current_user: current_user) }

    let_it_be(:group) { create(:group) }
    let_it_be(:developer) { create(:user) }
    let_it_be(:maintainer) { create(:user) }

    before_all do
      group.add_developer(developer)
      group.add_maintainer(maintainer)
    end

    before do
      allow(group).to receive(:default_branch_protection_settings)
        .and_return(Gitlab::Access::BranchProtection.protected_fully)
    end

    context 'when there is no current user' do
      let(:current_user) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when user cannot push to the default branch' do
      let(:current_user) { developer }

      it { is_expected.to be_falsey }
    end

    context 'when user can push to the default branch' do
      let(:current_user) { maintainer }

      it { is_expected.to be_truthy }
    end
  end
end
