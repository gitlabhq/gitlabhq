require 'spec_helper'

feature 'New project' do
  let(:user) { create(:admin) }

  before do
    sign_in(user)
  end

  it 'shows "New project" page' do
    visit new_project_path

    expect(page).to have_content('Project path')
    expect(page).to have_content('Project name')

    expect(page).to have_link('GitHub')
    expect(page).to have_link('Bitbucket')
    expect(page).to have_link('GitLab.com')
    expect(page).to have_link('Google Code')
    expect(page).to have_button('Repo by URL')
    expect(page).to have_link('GitLab export')
  end

  context 'Visibility level selector' do
    Gitlab::VisibilityLevel.options.each do |key, level|
      it "sets selector to #{key}" do
        stub_application_setting(default_project_visibility: level)

        visit new_project_path

        expect(find_field("project_visibility_level_#{level}")).to be_checked
      end

      it "saves visibility level #{level} on validation error" do
        visit new_project_path

        choose(s_(key))
        click_button('Create project')

        expect(find_field("project_visibility_level_#{level}")).to be_checked
      end
    end
  end

  context 'Namespace selector' do
    context 'with user namespace' do
      before do
        visit new_project_path
      end

      it 'selects the user namespace' do
        namespace = find('#project_namespace_id')

        expect(namespace.text).to eq user.username
      end
    end

    context 'with group namespace' do
      let(:group) { create(:group, :private, owner: user) }

      before do
        group.add_owner(user)
        visit new_project_path(namespace_id: group.id)
      end

      it 'selects the group namespace' do
        namespace = find('#project_namespace_id option[selected]')

        expect(namespace.text).to eq group.name
      end

      context 'on validation error' do
        before do
          fill_in('project_path', with: 'private-group-project')
          choose('Internal')
          click_button('Create project')

          expect(page).to have_css '.project-edit-errors .alert.alert-danger'
        end

        it 'selects the group namespace' do
          namespace = find('#project_namespace_id option[selected]')

          expect(namespace.text).to eq group.name
        end
      end
    end

    context 'with subgroup namespace' do
      let(:group) { create(:group, :private, owner: user) }
      let(:subgroup) { create(:group, parent: group) }

      before do
        group.add_master(user)
        visit new_project_path(namespace_id: subgroup.id)
      end

      it 'selects the group namespace' do
        namespace = find('#project_namespace_id option[selected]')

        expect(namespace.text).to eq subgroup.full_path
      end
    end
  end

  context 'Import project options' do
    before do
      visit new_project_path
    end

    context 'from git repository url' do
      before do
        first('.import_git').click
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

      it 'shows mirror repository checkbox enabled', :js do
        expect(page).to have_unchecked_field('Mirror repository', disabled: false)
      end
    end

    context 'from GitHub' do
      before do
        first('.import_github').click
      end

      it 'shows import instructions' do
        expect(page).to have_content('Import Projects from GitHub')
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
