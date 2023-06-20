# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project deploy keys', :js, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project_empty_repo) }
  let_it_be(:deploy_keys_project) { create(:deploy_keys_project, project: project) }
  let_it_be(:deploy_key) { deploy_keys_project.deploy_key }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'editing key' do
    it 'shows fingerprints' do
      visit edit_project_deploy_key_path(project, deploy_key)

      expect(page).to have_content('Fingerprint (SHA256)')
      expect(find('#deploy_key_fingerprint_sha256').value).to eq(deploy_key.fingerprint_sha256)

      if Gitlab::FIPS.enabled?
        expect(page).not_to have_content('Fingerprint (MD5)')
      else
        expect(page).to have_content('Fingerprint (MD5)')
        expect(find('#deploy_key_fingerprint').value).to eq(deploy_key.fingerprint)
      end
    end
  end

  describe 'removing key' do
    before do
      visit project_settings_repository_path(project)
    end

    it 'removes association between project and deploy key' do
      page.within(find('.rspec-deploy-keys-settings')) do
        expect(page).to have_selector('.deploy-key', count: 1)

        click_button 'Remove'
        click_button 'Remove deploy key'

        wait_for_requests

        expect(page).to have_selector('.deploy-key', count: 0)
      end
    end
  end
end
