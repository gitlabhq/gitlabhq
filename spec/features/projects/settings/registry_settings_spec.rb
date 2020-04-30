# frozen_string_literal: true

require 'spec_helper'

describe 'Project > Settings > CI/CD > Container registry tag expiration policy', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace, container_registry_enabled: container_registry_enabled) }
  let(:container_registry_enabled) { true }

  before do
    sign_in(user)
    stub_container_registry_config(enabled: true)
    stub_feature_flags(new_variables_ui: false)
  end

  context 'as owner' do
    before do
      visit project_settings_ci_cd_path(project)
    end

    it 'shows available section' do
      settings_block = find('#js-registry-policies')
      expect(settings_block).to have_text 'Container Registry tag expiration policy'
    end

    it 'saves expiration policy submit the form' do
      within '#js-registry-policies' do
        within '.card-body' do
          select('7 days until tags are automatically removed', from: 'Expiration interval:')
          select('Every day', from: 'Expiration schedule:')
          select('50 tags per image name', from: 'Number of tags to retain:')
          fill_in('Tags with names matching this regex pattern will expire:', with: '*-production')
        end
        submit_button = find('.card-footer .btn.btn-success')
        expect(submit_button).not_to be_disabled
        submit_button.click
      end
      toast = find('.gl-toast')
      expect(toast).to have_content('Expiration policy successfully saved.')
    end
  end

  context 'when registry is disabled' do
    before do
      stub_container_registry_config(enabled: false)
      visit project_settings_ci_cd_path(project)
    end

    it 'does not exists' do
      expect(page).not_to have_selector('#js-registry-policies')
    end
  end

  context 'when container registry is disabled on project' do
    let(:container_registry_enabled) { false }

    before do
      visit project_settings_ci_cd_path(project)
    end

    it 'does not exists' do
      expect(page).not_to have_selector('#js-registry-policies')
    end
  end
end
