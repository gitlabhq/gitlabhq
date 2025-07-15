# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['WorkItem'], feature_category: :team_planning do
  specify { expect(described_class.graphql_name).to eq('WorkItem') }

  specify { expect(described_class).to require_graphql_authorizations(:read_work_item) }

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::WorkItem) }

  specify { expect(described_class.interfaces).to include(Types::TodoableInterface) }

  it 'has specific fields' do
    fields = %i[
      author
      confidential
      description
      description_html
      id
      iid
      imported
      lock_version
      namespace
      project
      state title
      title_html
      userPermissions
      widgets
      work_item_type
      created_at
      updated_at
      closed_at
      web_url
      create_note_email
      reference
      archived
      name
      duplicatedToWorkItemUrl
      movedToWorkItemUrl
      comment_templates_paths
      showPlanUpgradePromotion
      hidden
    ]

    expect(described_class).to have_graphql_fields(*fields).at_least
  end

  describe 'pagination and count' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public) }

    let(:field_name) { 'workItems' }

    it_behaves_like 'issuables pagination and count' do
      let_it_be(:issuables) { create_list(:work_item, 10, project: project, created_at: now) }
      let(:container_name) { 'project' }
      let(:container) { project }
    end
  end

  describe '.authorization_scopes' do
    it 'allows ai_workflows scope token' do
      expect(described_class.authorization_scopes).to include(:ai_workflows)
    end
  end

  describe 'fields with :ai_workflows scope' do
    expected_scoped_fields = %w[
      author closedAt confidential createdAt description id iid imported namespace project
      state title updatedAt userDiscussionsCount widgets workItemType archived
    ]

    expected_scoped_fields.each do |field_name|
      it "includes :ai_workflows scope for the #{field_name} field" do
        field = described_class.fields[field_name]
        expect(field.instance_variable_get(:@scopes)).to include(:ai_workflows)
      end
    end
  end
end
