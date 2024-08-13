# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Projects > Settings > User manages merge request settings', feature_category: :code_review_workflow do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, :public, namespace: user.namespace, path: 'gitlab', name: 'sample') }

  before do
    sign_in(user)
    visit project_settings_merge_requests_path(project)
  end

  it 'shows "Merge commit" strategy' do
    page.within '.merge-request-settings-form' do
      expect(page).to have_content 'Merge commit'
    end
  end

  it 'shows "Merge commit with semi-linear history " strategy' do
    page.within '.merge-request-settings-form' do
      expect(page).to have_content 'Merge commit with semi-linear history'
    end
  end

  it 'shows "Fast-forward merge" strategy' do
    page.within '.merge-request-settings-form' do
      expect(page).to have_content 'Fast-forward merge'
    end
  end

  it 'shows Squash commit options', :aggregate_failures do
    page.within '.merge-request-settings-form' do
      expect(page).to have_content 'Do not allow'
      expect(page).to have_content 'Squashing is never performed and the checkbox is hidden.'

      expect(page).to have_content 'Allow'
      expect(page).to have_content 'Checkbox is visible and unselected by default.'

      expect(page).to have_content 'Encourage'
      expect(page).to have_content 'Checkbox is visible and selected by default.'

      expect(page).to have_content 'Require'
      expect(page).to have_content 'Squashing is always performed. Checkbox is visible and selected, and users cannot change it.'
    end
  end

  context 'when Merge Request and Pipelines are initially enabled', :js do
    context 'when Pipelines are initially enabled' do
      it 'shows the Merge Requests settings' do
        expect(page).to have_content 'Pipelines must succeed'
        expect(page).to have_content 'All threads must be resolved'

        visit edit_project_path(project)

        find('.project-feature-controls[data-for="project[project_feature_attributes][merge_requests_access_level]"] .gl-toggle').click
        find_by_testid('project-features-save-button').send_keys(:return)

        visit project_settings_merge_requests_path(project)

        expect(page).to have_content "Page not found"
      end
    end

    context 'when Pipelines are initially disabled', :js do
      before do
        project.project_feature.update_attribute('builds_access_level', ProjectFeature::DISABLED)
        visit project_settings_merge_requests_path(project)
      end

      it 'shows the Merge Requests settings that do not depend on Builds feature' do
        expect(page).to have_content 'Pipelines must succeed'
        expect(page).to have_content 'All threads must be resolved'

        visit edit_project_path(project)

        find('.project-feature-controls[data-for="project[project_feature_attributes][builds_access_level]"] .gl-toggle').click
        find_by_testid('project-features-save-button').send_keys(:return)

        visit project_settings_merge_requests_path(project)

        expect(page).to have_content 'Pipelines must succeed'
        expect(page).to have_content 'All threads must be resolved'
      end
    end
  end

  context 'when Merge Request are initially disabled', :js do
    before do
      project.project_feature.update_attribute('merge_requests_access_level', ProjectFeature::DISABLED)
      visit project_settings_merge_requests_path(project)
    end

    it 'does not show the Merge Requests settings' do
      expect(page).not_to have_content 'Pipelines must succeed'
      expect(page).not_to have_content 'All threads must be resolved'

      visit edit_project_path(project)

      within('.sharing-permissions-form') do
        find('.project-feature-controls[data-for="project[project_feature_attributes][merge_requests_access_level]"] .gl-toggle').click
        find_by_testid('project-features-save-button').send_keys(:return)
      end

      visit project_settings_merge_requests_path(project)

      expect(page).to have_content 'Pipelines must succeed'
      expect(page).to have_content 'All threads must be resolved'
    end
  end

  describe 'Checkbox to enable merge request link', :js do
    it 'is initially checked' do
      checkbox = find_field('project_printing_merge_request_link_enabled')
      expect(checkbox).to be_checked
    end

    it 'when unchecked sets :printing_merge_request_link_enabled to false' do
      uncheck('project_printing_merge_request_link_enabled')
      within('.merge-request-settings-form') do
        find('.rspec-save-merge-request-changes')
        click_on('Save changes')
      end

      wait_for_all_requests

      checkbox = find_field('project_printing_merge_request_link_enabled')

      expect(checkbox).not_to be_checked

      project.reload
      expect(project.printing_merge_request_link_enabled).to be(false)
    end
  end

  describe 'Checkbox to remove source branch after merge', :js do
    it 'is initially checked' do
      checkbox = find_field('project_remove_source_branch_after_merge')
      expect(checkbox).to be_checked
    end

    it 'when unchecked sets :remove_source_branch_after_merge to false' do
      uncheck('project_remove_source_branch_after_merge')
      within('.merge-request-settings-form') do
        find('.rspec-save-merge-request-changes')
        click_on('Save changes')
      end

      wait_for_all_requests

      checkbox = find_field('project_remove_source_branch_after_merge')

      expect(checkbox).not_to be_checked

      project.reload
      expect(project.remove_source_branch_after_merge).to be(false)
    end
  end

  describe 'Squash commits when merging', :js do
    it 'initially has :squash_option set to :default_off' do
      radio = find_field('project_project_setting_attributes_squash_option_default_off')
      expect(radio).to be_checked
    end

    it 'allows :squash_option to be set to :default_on' do
      choose('project_project_setting_attributes_squash_option_default_on')

      within('.merge-request-settings-form') do
        find('.rspec-save-merge-request-changes')
        click_on('Save changes')
      end

      wait_for_requests

      radio = find_field('project_project_setting_attributes_squash_option_default_on')

      expect(radio).to be_checked
      expect(project.reload.project_setting.squash_option).to eq('default_on')
    end

    it 'allows :squash_option to be set to :always' do
      choose('project_project_setting_attributes_squash_option_always')

      within('.merge-request-settings-form') do
        find('.rspec-save-merge-request-changes')
        click_on('Save changes')
      end

      wait_for_requests

      radio = find_field('project_project_setting_attributes_squash_option_always')

      expect(radio).to be_checked
      expect(project.reload.project_setting.squash_option).to eq('always')
    end

    it 'allows :squash_option to be set to :never' do
      choose('project_project_setting_attributes_squash_option_never')

      within('.merge-request-settings-form') do
        find('.rspec-save-merge-request-changes')
        click_on('Save changes')
      end

      wait_for_requests

      radio = find_field('project_project_setting_attributes_squash_option_never')

      expect(radio).to be_checked
      expect(project.reload.project_setting.squash_option).to eq('never')
    end
  end

  describe 'target project settings' do
    context 'when project is a fork' do
      let_it_be(:upstream) { create(:project, :public) }

      let(:project) { fork_project(upstream, user) }

      it 'allows to change merge request target project behavior' do
        expect(page).to have_content 'The default target project for merge requests'

        radio = find_field('project_project_setting_attributes_mr_default_target_self_false')
        expect(radio).to be_checked

        choose('project_project_setting_attributes_mr_default_target_self_true')

        within('.merge-request-settings-form') do
          find('.rspec-save-merge-request-changes')
          click_on('Save changes')
        end

        wait_for_requests

        radio = find_field('project_project_setting_attributes_mr_default_target_self_true')

        expect(radio).to be_checked
        expect(project.reload.project_setting.mr_default_target_self).to be_truthy
      end
    end

    it 'does not show target project section' do
      expect(page).not_to have_content 'The default target project for merge requests'
    end
  end
end
