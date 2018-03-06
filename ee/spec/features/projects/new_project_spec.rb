require 'spec_helper'

feature 'New project' do
  let(:user) { create(:admin) }

  before do
    sign_in(user)
  end

  context 'repository mirrors' do
    context 'when licensed' do
      before do
        stub_licensed_features(repository_mirrors: true)
      end

      it 'shows mirror repository checkbox enabled', :js do
        visit new_project_path
        find('#import-project-tab').click
        first('.js-import-git-toggle-button').click

        expect(page).to have_unchecked_field('Mirror repository', disabled: false)
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'does not show mirror repository option' do
        visit new_project_path
        first('.js-import-git-toggle-button').click

        expect(page).not_to have_content('Mirror repository')
      end
    end
  end

  context 'CI/CD for external repositories', :js do
    context 'when licensed' do
      before do
        stub_licensed_features(ci_cd_projects: true)
      end

      it 'shows CI/CD tab' do
        visit new_project_path

        expect(page).to have_css('#ci-cd-project-tab')

        find('#ci-cd-project-tab').click

        expect(page).to have_css('#ci-cd-project-pane')
      end

      it 'creates CI/CD project from repo URL' do
        visit new_project_path
        find('#ci-cd-project-tab').click

        page.within '#ci-cd-project-pane' do
          find('.js-import-git-toggle-button').click

          fill_in 'project_import_url', with: 'http://foo.git'
          fill_in 'project_path', with: 'ci-cd-project1'
          choose 'project_visibility_level_20'
          click_button 'Create project'

          created_project = Project.last
          expect(current_path).to eq(project_path(created_project))
          expect(created_project.mirror).to eq(true)
          expect(created_project.project_feature).not_to be_issues_enabled
        end
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(ci_cd_projects: false)
      end

      it 'does not show CI/CD only tab' do
        visit new_project_path

        expect(page).not_to have_css('#ci-cd-project-tab')
      end
    end
  end
end
