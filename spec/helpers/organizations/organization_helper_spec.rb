# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationHelper, feature_category: :cell do
  let_it_be(:organization) { build_stubbed(:organization) }
  let_it_be(:new_group_path) { '/groups/new' }
  let_it_be(:new_project_path) { '/projects/new' }
  let_it_be(:organizations_empty_state_svg_path) { 'illustrations/empty-state/empty-organizations-md.svg' }
  let_it_be(:organizations_path) { '/-/organizations/' }
  let_it_be(:root_url) { 'http://127.0.0.1:3000/' }
  let_it_be(:groups_empty_state_svg_path) { 'illustrations/empty-state/empty-groups-md.svg' }
  let_it_be(:projects_empty_state_svg_path) { 'illustrations/empty-state/empty-projects-md.svg' }

  before do
    allow(helper).to receive(:new_group_path).and_return(new_group_path)
    allow(helper).to receive(:new_project_path).and_return(new_project_path)
    allow(helper).to receive(:image_path).with(organizations_empty_state_svg_path)
      .and_return(organizations_empty_state_svg_path)
    allow(helper).to receive(:organizations_path).and_return(organizations_path)
    allow(helper).to receive(:root_url).and_return(root_url)
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
      expect(organization).to receive(:avatar_url).with(size: 128).and_return('avatar.jpg')
      expect(
        Gitlab::Json.parse(
          helper.organization_show_app_data(organization)
        )
      ).to eq(
        {
          'organization' => {
            'id' => organization.id,
            'name' => organization.name,
            'avatar_url' => 'avatar.jpg'
          },
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

  describe '#organization_new_app_data' do
    it 'returns expected json' do
      expect(Gitlab::Json.parse(helper.organization_new_app_data)).to eq(
        {
          'organizations_path' => organizations_path,
          'root_url' => root_url
        }
      )
    end
  end

  describe '#home_organization_setting_app_data' do
    it 'returns expected json' do
      current_user = build_stubbed(:user)
      allow(helper).to receive(:current_user).and_return(current_user)

      expect(Gitlab::Json.parse(helper.home_organization_setting_app_data)).to eq(
        {
          'initial_selection' => current_user.user_preference.home_organization_id
        }
      )
    end
  end

  describe '#organization_settings_general_app_data' do
    it 'returns expected json' do
      expect(organization).to receive(:avatar_url).with(size: 192).and_return('avatar.jpg')
      expect(Gitlab::Json.parse(helper.organization_settings_general_app_data(organization))).to eq(
        {
          'organization' => {
            'id' => organization.id,
            'name' => organization.name,
            'path' => organization.path,
            'avatar' => 'avatar.jpg'
          },
          'organizations_path' => organizations_path,
          'root_url' => root_url
        }
      )
    end
  end

  describe '#organization_user_app_data' do
    it 'returns expected json' do
      expect(Gitlab::Json.parse(helper.organization_user_app_data(organization))).to eq(
        {
          'organization_gid' => organization.to_global_id.to_s,
          'paths' => {
            'admin_user' => admin_user_path(:id)
          }
        }
      )
    end
  end
end
