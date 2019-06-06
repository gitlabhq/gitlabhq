require 'spec_helper'

describe 'New project' do
  include Select2Helper

  let(:user) { create(:admin) }

  before do
    sign_in(user)
  end

  it 'shows "New project" page', :js do
    visit new_project_path

    expect(page).to have_content('Project name')
    expect(page).to have_content('Project URL')
    expect(page).to have_content('Project slug')

    find('#import-project-tab').click

    expect(page).to have_link('GitHub')
    expect(page).to have_link('Bitbucket')
    expect(page).to have_link('GitLab.com')
    expect(page).to have_link('Google Code')
    expect(page).to have_button('Repo by URL')
    expect(page).to have_link('GitLab export')
  end

  describe 'manifest import option' do
    before do
      visit new_project_path

      find('#import-project-tab').click
    end

    context 'when using postgres', :postgresql do
      it { expect(page).to have_link('Manifest file') }
    end

    context 'when using mysql', :mysql do
      it { expect(page).not_to have_link('Manifest file') }
    end
  end

  context 'Visibility level selector', :js do
    Gitlab::VisibilityLevel.options.each do |key, level|
      it "sets selector to #{key}" do
        stub_application_setting(default_project_visibility: level)

        visit new_project_path
        page.within('#blank-project-pane') do
          expect(find_field("project_visibility_level_#{level}")).to be_checked
        end
      end

      it "saves visibility level #{level} on validation error" do
        visit new_project_path

        choose(s_(key))
        click_button('Create project')
        page.within('#blank-project-pane') do
          expect(find_field("project_visibility_level_#{level}")).to be_checked
        end
      end
    end

    context 'when group visibility is private but default is internal' do
      before do
        stub_application_setting(default_project_visibility: Gitlab::VisibilityLevel::INTERNAL)
      end

      it 'has private selected' do
        group = create(:group, visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        visit new_project_path(namespace_id: group.id)

        page.within('#blank-project-pane') do
          expect(find_field("project_visibility_level_#{Gitlab::VisibilityLevel::PRIVATE}")).to be_checked
        end
      end
    end

    context 'when group visibility is public but user requests private' do
      before do
        stub_application_setting(default_project_visibility: Gitlab::VisibilityLevel::INTERNAL)
      end

      it 'has private selected' do
        group = create(:group, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        visit new_project_path(namespace_id: group.id, project: { visibility_level: Gitlab::VisibilityLevel::PRIVATE })

        page.within('#blank-project-pane') do
          expect(find_field("project_visibility_level_#{Gitlab::VisibilityLevel::PRIVATE}")).to be_checked
        end
      end
    end
  end

  context 'Readme selector' do
    it 'shows the initialize with Readme checkbox on "Blank project" tab' do
      visit new_project_path

      expect(page).to have_css('input#project_initialize_with_readme')
      expect(page).to have_content('Initialize repository with a README')
    end

    it 'does not show the initialize with Readme checkbox on "Create from template" tab' do
      visit new_project_path
      find('#create-from-template-pane').click
      first('.choose-template').click

      page.within '.project-fields-form' do
        expect(page).not_to have_css('input#project_initialize_with_readme')
        expect(page).not_to have_content('Initialize repository with a README')
      end
    end

    it 'does not show the initialize with Readme checkbox on "Import project" tab' do
      visit new_project_path
      find('#import-project-tab').click
      first('.js-import-git-toggle-button').click

      page.within '.toggle-import-form' do
        expect(page).not_to have_css('input#project_initialize_with_readme')
        expect(page).not_to have_content('Initialize repository with a README')
      end
    end
  end

  context 'Namespace selector' do
    context 'with user namespace' do
      before do
        visit new_project_path
      end

      it 'selects the user namespace' do
        page.within('#blank-project-pane') do
          namespace = find('#project_namespace_id')

          expect(namespace.text).to eq user.username
        end
      end
    end

    context 'with group namespace' do
      let(:group) { create(:group, :private) }

      before do
        group.add_owner(user)
        visit new_project_path(namespace_id: group.id)
      end

      it 'selects the group namespace' do
        page.within('#blank-project-pane') do
          namespace = find('#project_namespace_id option[selected]')

          expect(namespace.text).to eq group.name
        end
      end
    end

    context 'with subgroup namespace' do
      let(:group) { create(:group) }
      let(:subgroup) { create(:group, parent: group) }

      before do
        group.add_maintainer(user)
        visit new_project_path(namespace_id: subgroup.id)
      end

      it 'selects the group namespace' do
        page.within('#blank-project-pane') do
          namespace = find('#project_namespace_id option[selected]')

          expect(namespace.text).to eq subgroup.full_path
        end
      end
    end

    context 'when changing namespaces dynamically', :js do
      let(:public_group) { create(:group, :public) }
      let(:internal_group) { create(:group, :internal) }
      let(:private_group) { create(:group, :private) }

      before do
        public_group.add_owner(user)
        internal_group.add_owner(user)
        private_group.add_owner(user)
        visit new_project_path(namespace_id: public_group.id)
      end

      it 'enables the correct visibility options' do
        select2(user.namespace_id, from: '#project_namespace_id')
        expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PRIVATE}")).not_to be_disabled
        expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::INTERNAL}")).not_to be_disabled
        expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PUBLIC}")).not_to be_disabled

        select2(public_group.id, from: '#project_namespace_id')
        expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PRIVATE}")).not_to be_disabled
        expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::INTERNAL}")).not_to be_disabled
        expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PUBLIC}")).not_to be_disabled

        select2(internal_group.id, from: '#project_namespace_id')
        expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PRIVATE}")).not_to be_disabled
        expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::INTERNAL}")).not_to be_disabled
        expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PUBLIC}")).to be_disabled

        select2(private_group.id, from: '#project_namespace_id')
        expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PRIVATE}")).not_to be_disabled
        expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::INTERNAL}")).to be_disabled
        expect(find("#project_visibility_level_#{Gitlab::VisibilityLevel::PUBLIC}")).to be_disabled
      end
    end
  end

  context 'Import project options', :js do
    before do
      visit new_project_path
      find('#import-project-tab').click
    end

    context 'from git repository url, "Repo by URL"' do
      before do
        first('.js-import-git-toggle-button').click
      end

      it 'does not autocomplete sensitive git repo URL' do
        autocomplete = find('#project_import_url')['autocomplete']

        expect(autocomplete).to eq('off')
      end

      it 'shows import instructions' do
        git_import_instructions = first('.js-toggle-content')

        expect(git_import_instructions).to be_visible
        expect(git_import_instructions).to have_content 'Git repository URL'
      end

      it 'keeps "Import project" tab open after form validation error' do
        collision_project = create(:project, name: 'test-name-collision', namespace: user.namespace)

        fill_in 'project_import_url', with: collision_project.http_url_to_repo
        fill_in 'project_name', with: collision_project.name

        click_on 'Create project'

        expect(page).to have_css('#import-project-pane.active')
        expect(page).not_to have_css('.toggle-import-form.hide')
      end
    end

    context 'from GitHub' do
      before do
        first('.js-import-github').click
      end

      it 'shows import instructions' do
        expect(page).to have_content('Import repositories from GitHub')
        expect(current_path).to eq new_import_github_path
      end
    end

    context 'from Google Code' do
      before do
        first('.import_google_code').click
      end

      it 'shows import instructions' do
        expect(page).to have_content('Import projects from Google Code')
        expect(current_path).to eq new_import_google_code_path
      end
    end

    context 'from manifest file', :postgresql do
      before do
        first('.import_manifest').click
      end

      it 'shows import instructions' do
        expect(page).to have_content('Manifest file import')
        expect(current_path).to eq new_import_manifest_path
      end
    end
  end

  context 'Namespace selector' do
    context 'with group with DEVELOPER_MAINTAINER_PROJECT_ACCESS project_creation_level' do
      let(:group) { create(:group, project_creation_level: ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS) }

      before do
        group.add_developer(user)
        visit new_project_path(namespace_id: group.id)
      end

      it 'selects the group namespace' do
        page.within('#blank-project-pane') do
          namespace = find('#project_namespace_id option[selected]')

          expect(namespace.text).to eq group.full_path
        end
      end
    end
  end
end
