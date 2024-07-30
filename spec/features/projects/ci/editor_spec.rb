# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipeline Editor', :js, feature_category: :pipeline_composition do
  include Features::SourceEditorSpecHelpers
  include ListboxHelpers

  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }

  let(:default_branch) { 'main' }
  let(:other_branch) { 'test' }
  let(:branch_with_invalid_ci) { 'despair' }
  let(:branch_without_ci) { 'empty' }

  let(:default_content) { 'Default' }

  let(:valid_content) do
    <<~YAML
    ---
    stages:
      - Build
      - Test
    job_a:
      script: echo hello
      stage: Build
    job_b:
      script: echo hello from job b
      stage: Test
    YAML
  end

  let(:invalid_content) do
    <<~YAML

      job3:
      stage: stage_foo
      script: echo 'Done.'
    YAML
  end

  before do
    sign_in(user)
    project.add_developer(user)

    project.repository.create_file(user, project.ci_config_path_or_default, default_content, message: 'Create CI file for main', branch_name: default_branch)
    project.repository.create_file(user, project.ci_config_path_or_default, valid_content, message: 'Create CI file for test', branch_name: other_branch)
    project.repository.create_file(user, project.ci_config_path_or_default, invalid_content, message: 'Create CI file for test', branch_name: branch_with_invalid_ci)
    project.repository.create_file(user, 'index.js', "file", message: 'New js file', branch_name: branch_without_ci)

    visit project_ci_pipeline_editor_path(project)
    wait_for_requests
  end

  describe 'Default tabs' do
    it 'renders the edit tab as the default' do
      expect(page).to have_selector('[data-testid="editor-tab"]')
    end

    it 'renders the visualize, validate and full configuration tabs', :aggregate_failures do
      expect(page).to have_selector('[data-testid="visualization-tab"]', visible: :hidden)
      expect(page).to have_selector('[data-testid="validate-tab"]', visible: :hidden)
      expect(page).to have_selector('[data-testid="merged-tab"]', visible: :hidden)
    end
  end

  describe 'when there are no CI config file' do
    before do
      visit project_ci_pipeline_editor_path(project, branch_name: branch_without_ci)
    end

    it 'renders the empty page', :aggregate_failures do
      expect(page).to have_content 'Optimize your workflow with CI/CD Pipelines'
      expect(page).to have_selector '[data-testid="create-new-ci-button"]'
    end

    context 'when clicking on the create new CI button' do
      before do
        click_button 'Configure pipeline'
      end

      it 'renders the source editor with default content', :aggregate_failures do
        expect(page).to have_selector('#source-editor-')

        page.within('#source-editor-') do
          expect(page).to have_content('This file is a template, and might need editing before it works on your project.')
        end
      end
    end
  end

  describe 'When CI yml has valid syntax' do
    before do
      visit project_ci_pipeline_editor_path(project, branch_name: other_branch)
      wait_for_requests
    end

    it 'shows "Pipeline syntax is correct" in the lint widget' do
      within_testid('validation-segment') do
        expect(page).to have_content("Pipeline syntax is correct")
      end
    end

    it 'shows the graph in the visualization tab' do
      click_link "Visualize"

      within_testid('graph-container') do
        expect(page).to have_content("job_a")
      end
    end

    it 'can simulate pipeline in the validate tab' do
      click_link "Validate"

      click_button "Validate pipeline"
      wait_for_requests

      expect(page).to have_content("Simulation completed successfully")
    end

    it 'renders the merged yaml in the full configuration tab' do
      click_link "Full configuration"

      within_testid('merged-tab') do
        expect(page).to have_content("job_a")
      end
    end
  end

  describe 'When CI yml has invalid syntax' do
    before do
      visit project_ci_pipeline_editor_path(project, branch_name: branch_with_invalid_ci)
      wait_for_requests
    end

    it 'shows "Syntax is invalid" in the lint widget' do
      within_testid('validation-segment') do
        expect(page).to have_content("This GitLab CI configuration is invalid")
      end
    end

    it 'does not render the graph in the visualization tab and shows error' do
      click_link "Visualize"

      expect(page).not_to have_selector('[data-testid="graph-container"')
      expect(page).to have_content("Your CI/CD configuration syntax is invalid. Select the Validate tab for more details.")
    end

    it 'gets a simulation error in the validate tab' do
      click_link "Validate"

      click_button "Validate pipeline"
      wait_for_requests

      expect(page).to have_content("Pipeline simulation completed with errors")
    end

    it 'renders merged yaml config' do
      click_link "Full configuration"

      within_testid('merged-tab') do
        expect(page).to have_content("job3")
      end
    end
  end

  describe 'with unparsable yaml' do
    it 'renders an error in the merged yaml tab' do
      click_link "Full configuration"

      within_testid('merged-tab') do
        expect(page).not_to have_content("job_a")
        expect(page).to have_content("Could not load full configuration content")
      end
    end
  end

  shared_examples 'default branch switcher behavior' do
    it 'displays current branch' do
      within_testid('branch-selector') do
        expect(page).to have_content(default_branch)
        expect(page).not_to have_content(other_branch)
      end
    end

    it 'displays updated current branch after switching branches' do
      switch_to_branch(other_branch)

      within_testid('branch-selector') do
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

      within_testid('branch-selector') do
        expect(page).to have_content('new_branch')
        expect(page).not_to have_content(default_branch)
      end
    end
  end

  it 'user sees the Pipeline Editor page' do
    expect(page).to have_content('Pipeline editor')
  end

  describe 'Branch Switcher' do
    def switch_to_branch(branch)
      # close button for the popover
      find_by_testid('close-button').click

      within_testid 'branch-selector' do
        toggle_listbox
        select_listbox_item(branch, exact_text: true)
      end

      wait_for_requests
    end

    before do
      visit project_ci_pipeline_editor_path(project)
      wait_for_requests
    end

    it_behaves_like 'default branch switcher behavior'
  end

  describe 'Editor navigation' do
    context 'when no change is made' do
      it 'user can navigate away without a browser alert' do
        expect(page).to have_content('Pipeline editor')

        click_link 'Pipelines'

        page.within('#content-body') do
          expect(page).not_to have_content('Pipeline editor')
        end
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

        expect(page).to have_content('Pipeline editor')

        page.within('#source-editor-') do
          expect(page).to have_content("#{default_content}123")
        end
      end

      it 'user who tries to navigate away can confirm the action and discard their change', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/410496' do
        click_link 'Pipelines'

        page.driver.browser.switch_to.alert.accept

        expect(page).not_to have_content('Pipeline editor')
      end

      it 'user who creates a MR is taken to the merge request page without warnings' do
        expect(page).not_to have_content('New merge request')

        find_field('Branch').set 'new_branch'
        find_field('Start a new merge request with these changes').click

        click_button 'Commit changes'

        expect(page).not_to have_content('Pipeline editor')
        expect(page).to have_content('New merge request')
      end
    end
  end

  describe 'Commit Form' do
    context 'when targetting the main branch' do
      it 'does not show the option to create a Merge request', :aggregate_failures do
        expect(page).not_to have_selector('[data-testid="new-mr-checkbox"]')
        expect(page).not_to have_content('Start a new merge request with these changes')
      end
    end

    context 'when targetting any non-main branch' do
      before do
        find('#source-branch-field').set('new_branch', clear: :backspace)
      end

      it 'shows the option to create a Merge request', :aggregate_failures do
        expect(page).to have_selector('[data-testid="new-mr-checkbox"]')
        expect(page).to have_content('Start a new merge request with these changes')
      end
    end

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
        expect(page).to have_content(default_content)
        expect(page).not_to have_content("#{default_content}123")
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
        expect(page).to have_content("#{default_content}123")
      end
    end
  end
end
