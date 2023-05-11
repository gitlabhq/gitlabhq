# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipeline Editor', :js, feature_category: :pipeline_composition do
  include Features::SourceEditorSpecHelpers

  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }

  let(:default_branch) { 'main' }
  let(:other_branch) { 'test' }

  before do
    sign_in(user)
    project.add_developer(user)

    project.repository.create_file(user, project.ci_config_path_or_default, 'Default Content', message: 'Create CI file for main', branch_name: default_branch)
    project.repository.create_file(user, project.ci_config_path_or_default, 'Other Content', message: 'Create CI file for test', branch_name: other_branch)

    visit project_ci_pipeline_editor_path(project)
    wait_for_requests
  end

  shared_examples 'default branch switcher behavior' do
    def switch_to_branch(branch)
      find('[data-testid="branch-selector"]').click

      page.within '[data-testid="branch-selector"]' do
        click_button branch
        wait_for_requests
      end
    end

    it 'displays current branch' do
      page.within('[data-testid="branch-selector"]') do
        expect(page).to have_content(default_branch)
        expect(page).not_to have_content(other_branch)
      end
    end

    it 'displays updated current branch after switching branches' do
      switch_to_branch(other_branch)

      page.within('[data-testid="branch-selector"]') do
        expect(page).to have_content(other_branch)
        expect(page).not_to have_content(default_branch)
      end
    end

    it 'displays new branch as selected after commiting on a new branch' do
      find('#source-branch-field').set('new_branch', clear: :backspace)

      page.within('#source-editor-') do
        find('textarea').send_keys '123'
      end

      click_button 'Commit changes'

      page.within('[data-testid="branch-selector"]') do
        expect(page).to have_content('new_branch')
        expect(page).not_to have_content(default_branch)
      end
    end
  end

  it 'user sees the Pipeline Editor page' do
    expect(page).to have_content('Pipeline Editor')
  end

  describe 'Branch Switcher' do
    before do
      visit project_ci_pipeline_editor_path(project)
      wait_for_requests

      # close button for the popover
      find('[data-testid="close-button"]').click
    end

    it_behaves_like 'default branch switcher behavior'
  end

  describe 'Editor navigation' do
    context 'when no change is made' do
      it 'user can navigate away without a browser alert' do
        expect(page).to have_content('Pipeline Editor')

        click_link 'Pipelines'

        expect(page).not_to have_content('Pipeline Editor')
      end
    end

    context 'when a change is made' do
      before do
        page.within('#source-editor-') do
          find('textarea').send_keys '123'
          # It takes some time after sending keys for the vue
          # component to update
          sleep 1
        end
      end

      it 'user who tries to navigate away can cancel the action and keep their changes', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/410496' do
        click_link 'Pipelines'

        page.driver.browser.switch_to.alert.dismiss

        expect(page).to have_content('Pipeline Editor')

        page.within('#source-editor-') do
          expect(page).to have_content('Default Content123')
        end
      end

      it 'user who tries to navigate away can confirm the action and discard their change', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/410496' do
        click_link 'Pipelines'

        page.driver.browser.switch_to.alert.accept

        expect(page).not_to have_content('Pipeline Editor')
      end

      it 'user who creates a MR is taken to the merge request page without warnings' do
        expect(page).not_to have_content('New merge request')

        find_field('Branch').set 'new_branch'
        find_field('Start a new merge request with these changes').click

        click_button 'Commit changes'

        expect(page).not_to have_content('Pipeline Editor')
        expect(page).to have_content('New merge request')
      end
    end
  end

  describe 'Commit Form' do
    it 'is preserved when changing tabs' do
      find('#commit-message').set('message', clear: :backspace)
      find('#source-branch-field').set('new_branch', clear: :backspace)

      click_link 'Validate'
      click_link 'Edit'

      expect(find('#commit-message').value).to eq('message')
      expect(find('#source-branch-field').value).to eq('new_branch')
    end
  end

  describe 'Editor content' do
    it 'user can reset their CI configuration' do
      page.within('#source-editor-') do
        find('textarea').send_keys '123'
      end

      # It takes some time after sending keys for the reset
      # btn to register the changes inside the editor
      sleep 1
      click_button 'Reset'

      expect(page).to have_css('#reset-content')

      page.within('#reset-content') do
        click_button 'Reset file'
      end

      page.within('#source-editor-') do
        expect(page).to have_content('Default Content')
        expect(page).not_to have_content('Default Content123')
      end
    end

    it 'user can cancel reseting their CI configuration' do
      page.within('#source-editor-') do
        find('textarea').send_keys '123'
      end

      # It takes some time after sending keys for the reset
      # btn to register the changes inside the editor
      sleep 1
      click_button 'Reset'

      expect(page).to have_css('#reset-content')

      page.within('#reset-content') do
        click_button 'Cancel'
      end

      page.within('#source-editor-') do
        expect(page).to have_content('Default Content123')
      end
    end
  end
end
