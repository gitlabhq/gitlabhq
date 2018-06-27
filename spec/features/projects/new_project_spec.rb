require 'spec_helper'

feature 'New project' do
  include Select2Helper

  let(:user) { create(:admin) }

  before do
    sign_in(user)
  end

  it 'shows "New project" page', :js do
    visit new_project_path

    expect(page).to have_content('Project path')
    expect(page).to have_content('Project name')

    find('#import-project-tab').click

    expect(page).to have_link('GitHub')
    expect(page).to have_link('Bitbucket')
    expect(page).to have_link('GitLab.com')
    expect(page).to have_link('Google Code')
    expect(page).to have_button('Repo by URL')
    expect(page).to have_link('GitLab export')
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
        group.add_master(user)
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
        fill_in 'project_path', with: collision_project.path

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
  end
end
