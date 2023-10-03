# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationHelper, feature_category: :cell do
  let_it_be(:organization) { build_stubbed(:organization) }
  let_it_be(:new_group_path) { '/groups/new' }
  let_it_be(:new_project_path) { '/projects/new' }
  let_it_be(:organizations_empty_state_svg_path) { 'illustrations/empty-state/empty-organizations-md.svg' }
  let_it_be(:groups_empty_state_svg_path) { 'illustrations/empty-state/empty-groups-md.svg' }
  let_it_be(:projects_empty_state_svg_path) { 'illustrations/empty-state/empty-projects-md.svg' }

  before do
    allow(helper).to receive(:new_group_path).and_return(new_group_path)
    allow(helper).to receive(:new_project_path).and_return(new_project_path)
    allow(helper).to receive(:image_path).with(organizations_empty_state_svg_path)
      .and_return(organizations_empty_state_svg_path)
    allow(helper).to receive(:image_path).with(groups_empty_state_svg_path).and_return(groups_empty_state_svg_path)
    allow(helper).to receive(:image_path).with(projects_empty_state_svg_path).and_return(projects_empty_state_svg_path)
  end

  describe '#organization_show_app_data' do
    before do
      allow(helper).to receive(:groups_and_projects_organization_path)
        .with(organization)
        .and_return('/-/organizations/default/groups_and_projects')
    end

    it 'returns expected json' do
      expect(
        Gitlab::Json.parse(
          helper.organization_show_app_data(organization)
        )
      ).to eq(
        {
          'organization' => { 'id' => organization.id, 'name' => organization.name },
          'groups_and_projects_organization_path' => '/-/organizations/default/groups_and_projects',
          'new_group_path' => new_group_path,
          'new_project_path' => new_project_path,
          'groups_empty_state_svg_path' => groups_empty_state_svg_path,
          'projects_empty_state_svg_path' => projects_empty_state_svg_path,
          'association_counts' => {
            'groups' => 10,
            'projects' => 5,
            'users' => 1050
          }
        }
      )
    end
  end

  describe '#organization_groups_and_projects_app_data' do
    it 'returns expected json' do
      expect(
        Gitlab::Json.parse(
          helper.organization_groups_and_projects_app_data
        )
      ).to eq(
        {
          'new_group_path' => new_group_path,
          'new_project_path' => new_project_path,
          'groups_empty_state_svg_path' => groups_empty_state_svg_path,
          'projects_empty_state_svg_path' => projects_empty_state_svg_path
        }
      )
    end
  end

  describe '#organization_index_app_data' do
    it 'returns expected data object' do
      expect(helper.organization_index_app_data).to eq(
        {
          new_organization_url: new_organization_path,
          organizations_empty_state_svg_path: organizations_empty_state_svg_path
        }
      )
    end
  end
end
