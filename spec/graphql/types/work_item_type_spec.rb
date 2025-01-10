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
end
