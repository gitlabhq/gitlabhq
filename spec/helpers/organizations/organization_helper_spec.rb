# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationHelper, feature_category: :cell do
  include Devise::Test::ControllerHelpers

  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:organization_detail) { build_stubbed(:organization_detail, description_html: '<em>description</em>') }
  let_it_be(:organization) { organization_detail.organization }
  let_it_be(:organization_gid) { 'gid://gitlab/Organizations::Organization/1' }
  let_it_be(:new_group_path) { '/-/organizations/default/groups/new' }
  let_it_be(:new_project_path) { '/projects/new' }
  let_it_be(:organizations_empty_state_svg_path) { 'illustrations/empty-state/empty-organizations-md.svg' }
  let_it_be(:organizations_path) { '/-/organizations/' }
  let_it_be(:root_url) { 'http://127.0.0.1:3000/' }
  let_it_be(:groups_empty_state_svg_path) { 'illustrations/empty-state/empty-groups-md.svg' }
  let_it_be(:projects_empty_state_svg_path) { 'illustrations/empty-state/empty-projects-md.svg' }
  let_it_be(:preview_markdown_organizations_path) { '/-/organizations/preview_markdown' }
  let_it_be(:groups_and_projects_organization_path) { '/-/organizations/default/groups_and_projects' }
  let_it_be(:users_organization_path) { '/-/organizations/default/users' }

  let(:stubbed_results) do
    {
      'groups' => 10,
      'projects' => 50,
      'users' => 1050
    }
  end

  before do
    allow(organization).to receive(:to_global_id).and_return(organization_gid)
    allow(helper).to receive(:new_groups_organization_path).with(organization).and_return(new_group_path)
    allow(helper).to receive(:new_project_path).and_return(new_project_path)
    allow(helper).to receive(:image_path).with(organizations_empty_state_svg_path)
      .and_return(organizations_empty_state_svg_path)
    allow(helper).to receive(:organizations_path).and_return(organizations_path)
    allow(helper).to receive(:root_url).and_return(root_url)
    allow(helper).to receive(:image_path).with(groups_empty_state_svg_path).and_return(groups_empty_state_svg_path)
    allow(helper).to receive(:image_path).with(projects_empty_state_svg_path).and_return(projects_empty_state_svg_path)
    allow(helper).to receive(:preview_markdown_organizations_path).and_return(preview_markdown_organizations_path)
    allow(helper).to receive(:current_user).and_return(user)
    allow_next_instance_of(Organizations::OrganizationAssociationCounter) do |finder|
      allow(finder).to receive(:execute).and_return(stubbed_results)
    end
  end

  shared_examples 'includes that the user can create a group' do |method|
    it 'returns expected json' do
      expect(
        Gitlab::Json.parse(helper.send(method, organization))
      ).to include('can_create_group' => true)
    end
  end

  shared_examples 'includes that the user can create a project' do |method|
    it 'returns expected json' do
      expect(
        Gitlab::Json.parse(helper.send(method, organization))
      ).to include('can_create_project' => true)
    end
  end

  shared_examples 'includes that the organization has groups' do |method|
    it 'returns expected json' do
      expect(
        Gitlab::Json.parse(helper.send(method, organization))
      ).to include('has_groups' => true)
    end
  end

  describe '#organization_layout_nav' do
    context 'when current controller is not organizations' do
      it 'returns organization' do
        allow(helper).to receive(:current_controller?).with('organizations').and_return(false)

        expect(helper.organization_layout_nav).to eq('organization')
      end
    end

    context 'when current controller is organizations' do
      before do
        allow(helper).to receive(:current_controller?).with('organizations').and_return(true)
      end

      context 'when current action is index or new' do
        it 'returns your_work' do
          allow(helper).to receive(:current_action?).with(:index, :new).and_return(true)

          expect(helper.organization_layout_nav).to eq('your_work')
        end
      end

      context 'when current action is not index or new' do
        it 'returns organization' do
          allow(helper).to receive(:current_action?).with(:index, :new).and_return(false)

          expect(helper.organization_layout_nav).to eq('organization')
        end
      end
    end
  end

  describe '#organization_show_app_data' do
    before do
      allow(helper).to receive(:groups_and_projects_organization_path)
        .with(organization)
        .and_return(groups_and_projects_organization_path)

      allow(helper).to receive(:users_organization_path)
        .with(organization)
        .and_return(users_organization_path)
    end

    context 'when the user can create a group' do
      before do
        allow(helper).to receive(:can?).with(user, :create_group, organization).and_return(true)
      end

      include_examples 'includes that the user can create a group', 'organization_show_app_data'
    end

    context 'when the user can create a project' do
      before do
        allow(user).to receive(:can_create_project?).and_return(true)
      end

      include_examples 'includes that the user can create a project', 'organization_show_app_data'
    end

    context 'when the organization has groups' do
      before do
        allow(helper).to receive(:has_groups?).and_return(true)
      end

      include_examples 'includes that the organization has groups', 'organization_show_app_data'
    end

    it "includes all other non-conditional data" do
      expect(organization).to receive(:avatar_url).with(size: 128).and_return('avatar.jpg')

      expect(
        Gitlab::Json.parse(
          helper.organization_show_app_data(organization)
        )
      ).to include(
        {
          'organization_gid' => organization_gid,
          'organization' => {
            'id' => organization.id,
            'name' => organization.name,
            'description_html' => organization.description_html,
            'avatar_url' => 'avatar.jpg'
          },
          'groups_and_projects_organization_path' => groups_and_projects_organization_path,
          'users_organization_path' => users_organization_path,
          'new_group_path' => new_group_path,
          'new_project_path' => new_project_path,
          'groups_empty_state_svg_path' => groups_empty_state_svg_path,
          'projects_empty_state_svg_path' => projects_empty_state_svg_path,
          'association_counts' => stubbed_results
        }
      )
    end
  end

  describe '#organization_groups_and_projects_app_data' do
    context 'when the user can create a group' do
      before do
        allow(helper).to receive(:can?).with(user, :create_group, organization).and_return(true)
      end

      include_examples 'includes that the user can create a group', 'organization_groups_and_projects_app_data'
    end

    context 'when the user can create a project' do
      before do
        allow(user).to receive(:can_create_project?).and_return(true)
      end

      include_examples 'includes that the user can create a project', 'organization_groups_and_projects_app_data'
    end

    context 'when the organization has groups' do
      before do
        allow(helper).to receive(:has_groups?).and_return(true)
      end

      include_examples 'includes that the organization has groups', 'organization_groups_and_projects_app_data'
    end

    it "includes all other non-conditional data" do
      expect(
        Gitlab::Json.parse(
          helper.organization_groups_and_projects_app_data(organization)
        )
      ).to include(
        {
          'organization_gid' => organization_gid,
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
          'root_url' => root_url,
          'preview_markdown_path' => preview_markdown_organizations_path
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
            'description' => organization.description,
            'avatar' => 'avatar.jpg'
          },
          'organizations_path' => organizations_path,
          'root_url' => root_url,
          'preview_markdown_path' => preview_markdown_organizations_path
        }
      )
    end
  end

  describe '#organization_user_app_data' do
    it 'returns expected json' do
      expect(Gitlab::Json.parse(helper.organization_user_app_data(organization))).to eq(
        {
          'organization_gid' => organization_gid,
          'paths' => {
            'admin_user' => admin_user_path(:id)
          }
        }
      )
    end
  end

  describe '#organization_groups_new_app_data' do
    before do
      allow(helper).to receive(:groups_and_projects_organization_path)
        .with(organization, { display: 'groups' })
        .and_return(groups_and_projects_organization_path)
      allow(helper).to receive(:restricted_visibility_levels).and_return([])
      stub_application_setting(default_group_visibility: Gitlab::VisibilityLevel::PUBLIC)
    end

    it 'returns expected json' do
      expect(Gitlab::Json.parse(helper.organization_groups_new_app_data(organization))).to eq(
        {
          'organization_id' => organization.id,
          'base_path' => root_url,
          'groups_organization_path' => groups_and_projects_organization_path,
          'mattermost_enabled' => false,
          'available_visibility_levels' => [
            Gitlab::VisibilityLevel::PRIVATE,
            Gitlab::VisibilityLevel::INTERNAL,
            Gitlab::VisibilityLevel::PUBLIC
          ],
          'restricted_visibility_levels' => [],
          'default_visibility_level' => Gitlab::VisibilityLevel::PUBLIC,
          'path_maxlength' => ::Namespace::URL_MAX_LENGTH,
          'path_pattern' => Gitlab::PathRegex::NAMESPACE_FORMAT_REGEX_JS
        }
      )
    end
  end

  describe '#admin_organizations_index_app_data' do
    it 'returns expected json' do
      expect(Gitlab::Json.parse(helper.admin_organizations_index_app_data)).to eq(
        {
          'new_organization_url' => new_organization_path,
          'organizations_empty_state_svg_path' => organizations_empty_state_svg_path
        }
      )
    end
  end

  describe '#organization_projects_edit_app_data' do
    let_it_be(:project) { build_stubbed(:project, organization: organization) }

    before do
      allow(helper).to receive(:groups_and_projects_organization_path)
        .with(organization, { display: 'projects' })
        .and_return(groups_and_projects_organization_path)
    end

    it 'returns expected json' do
      expect(Gitlab::Json.parse(helper.organization_projects_edit_app_data(organization, project))).to eq(
        {
          'projects_organization_path' => groups_and_projects_organization_path,
          'preview_markdown_path' => preview_markdown_organizations_path,
          'project' => {
            'id' => project.id,
            'name' => project.name,
            'full_name' => project.full_name,
            'description' => project.description
          }
        }
      )
    end
  end
end
