# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationHelper, feature_category: :cell do
  include Devise::Test::ControllerHelpers

  let_it_be(:user) { build_stubbed(:user, organization_groups_projects_sort: 'name_asc') }
  let_it_be(:organization) { build_stubbed(:organization, :default) }
  let_it_be(:organization_detail) do
    build_stubbed(:organization_detail, organization: organization, description_html: '<em>description</em>')
  end

  let(:stubbed_results) do
    {
      'groups' => 10,
      'projects' => 50,
      'users' => 1050
    }
  end

  before do
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
          'organization_gid' => 'gid://gitlab/Organizations::Organization/1',
          'organization' => {
            'id' => organization.id,
            'name' => organization.name,
            'description_html' => organization.description_html,
            'avatar_url' => 'avatar.jpg'
          },
          'groups_and_projects_organization_path' => '/-/organizations/default/groups_and_projects',
          'users_organization_path' => '/-/organizations/default/users',
          'new_group_path' => '/-/organizations/default/groups/new',
          'groups_path' => '/-/organizations/default/groups',
          'new_project_path' => '/projects/new',
          'association_counts' => stubbed_results,
          'organization_groups_projects_sort' => 'name_asc',
          'organization_groups_projects_display' => 'projects'
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
          'organization_gid' => 'gid://gitlab/Organizations::Organization/1',
          'new_group_path' => '/-/organizations/default/groups/new',
          'groups_path' => '/-/organizations/default/groups',
          'new_project_path' => '/projects/new',
          'organization_groups_projects_sort' => 'name_asc',
          'organization_groups_projects_display' => 'projects',
          'user_preference_sort' => 'name_asc',
          'user_preference_display' => 'projects'
        }
      )
    end
  end

  describe '#organization_index_app_data' do
    it 'returns expected data object' do
      expect(helper.organization_index_app_data).to eq(
        {
          new_organization_url: new_organization_path
        }
      )
    end
  end

  describe '#organization_new_app_data' do
    it 'returns expected json' do
      expect(Gitlab::Json.parse(helper.organization_new_app_data)).to eq(
        {
          'organizations_path' => '/-/organizations',
          'root_url' => 'http://test.host/',
          'preview_markdown_path' => '/-/organizations/preview_markdown'
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
          'organizations_path' => '/-/organizations',
          'root_url' => 'http://test.host/',
          'preview_markdown_path' => '/-/organizations/preview_markdown'
        }
      )
    end
  end

  describe '#organization_user_app_data' do
    it 'returns expected json' do
      expect(Gitlab::Json.parse(helper.organization_user_app_data(organization))).to eq(
        {
          'organization_gid' => 'gid://gitlab/Organizations::Organization/1',
          'paths' => {
            'admin_user' => admin_user_path(:id)
          }
        }
      )
    end
  end

  describe '#organization_groups_new_app_data' do
    before do
      stub_application_setting(default_group_visibility: Gitlab::VisibilityLevel::PUBLIC)
    end

    it 'returns expected json' do
      expect(Gitlab::Json.parse(helper.organization_groups_new_app_data(organization))).to eq(
        {
          'base_path' => 'http://test.host/',
          'groups_and_projects_organization_path' => '/-/organizations/default/groups_and_projects?display=groups',
          'groups_organization_path' => '/-/organizations/default/groups',
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

  describe '#organization_groups_edit_app_data' do
    let_it_be(:group) { build_stubbed(:group, organization: organization) }

    it 'returns expected json' do
      expect(Gitlab::Json.parse(helper.organization_groups_edit_app_data(organization, group))).to eq(
        {
          'group' => {
            'id' => group.id,
            'full_name' => group.full_name,
            'name' => group.name,
            'path' => group.path,
            'full_path' => group.full_path,
            "visibility_level" => group.visibility_level
          },
          'base_path' => 'http://test.host/',
          'groups_and_projects_organization_path' => '/-/organizations/default/groups_and_projects?display=groups',
          'groups_organization_path' => '/-/organizations/default/groups',
          'available_visibility_levels' => [
            Gitlab::VisibilityLevel::PRIVATE,
            Gitlab::VisibilityLevel::INTERNAL,
            Gitlab::VisibilityLevel::PUBLIC
          ],
          'restricted_visibility_levels' => [],
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
          'new_organization_url' => new_organization_path
        }
      )
    end
  end

  describe '#organization_projects_edit_app_data' do
    let_it_be(:project) { build_stubbed(:project, organization: organization) }

    it 'returns expected json' do
      expect(Gitlab::Json.parse(helper.organization_projects_edit_app_data(organization, project))).to eq(
        {
          'projects_organization_path' => '/-/organizations/default/groups_and_projects?display=projects',
          'preview_markdown_path' => '/-/organizations/preview_markdown',
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

  describe '#organization_activity_app_data' do
    it 'returns expected data object' do
      expect(Gitlab::Json.parse(helper.organization_activity_app_data(organization))).to match(
        {
          'organization_activity_path' => '/-/organizations/default/activity.json',
          'organization_activity_event_types' => array_including(
            {
              'title' => 'Comments',
              'value' => EventFilter::COMMENTS
            },
            {
              'title' => 'Designs',
              'value' => EventFilter::DESIGNS
            },
            {
              'title' => 'Issue events',
              'value' => EventFilter::ISSUE
            },
            {
              'title' => 'Merge events',
              'value' => EventFilter::MERGED
            },
            {
              'title' => 'Push events',
              'value' => EventFilter::PUSH
            },
            {
              'title' => 'Team',
              'value' => EventFilter::TEAM
            },
            {
              'title' => 'Wiki',
              'value' => EventFilter::WIKI
            }
          ),
          'organization_activity_all_event' => EventFilter::ALL
        }
      )
    end
  end
end
