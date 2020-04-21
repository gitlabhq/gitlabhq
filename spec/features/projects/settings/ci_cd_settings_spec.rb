# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Settings > CI / CD settings' do
  let_it_be(:project) { create(:project_empty_repo) }
  let_it_be(:user) { create(:user) }
  let_it_be(:role) { :maintainer }

  context 'Deploy tokens' do
    let!(:deploy_token) { create(:deploy_token, projects: [project]) }

    before do
      project.add_role(user, role)
      sign_in(user)
      stub_container_registry_config(enabled: true)
      stub_feature_flags(ajax_new_deploy_token: { enabled: false, thing: project })
      visit project_settings_ci_cd_path(project)
    end

    it_behaves_like 'a deploy token in settings' do
      let(:entity_type) { 'project' }
    end
  end

  context 'Deploy Keys', :js do
    let_it_be(:private_deploy_key) { create(:deploy_key, title: 'private_deploy_key', public: false) }
    let_it_be(:public_deploy_key) { create(:another_deploy_key, title: 'public_deploy_key', public: true) }
    let(:new_ssh_key) { attributes_for(:key)[:key] }

    before do
      project.add_role(user, role)
      sign_in(user)
    end

    it 'get list of keys' do
      project.deploy_keys << private_deploy_key
      project.deploy_keys << public_deploy_key

      visit project_settings_ci_cd_path(project)

      expect(page).to have_content('private_deploy_key')
      expect(page).to have_content('public_deploy_key')
    end

    it 'add a new deploy key' do
      visit project_settings_ci_cd_path(project)

      fill_in 'deploy_key_title', with: 'new_deploy_key'
      fill_in 'deploy_key_key', with: new_ssh_key
      check 'deploy_key_deploy_keys_projects_attributes_0_can_push'
      click_button 'Add key'

      expect(page).to have_content('new_deploy_key')
      expect(page).to have_content('Write access allowed')
    end

    it 'edit an existing deploy key' do
      project.deploy_keys << private_deploy_key
      visit project_settings_ci_cd_path(project)

      find('.deploy-key', text: private_deploy_key.title).find('.ic-pencil').click

      fill_in 'deploy_key_title', with: 'updated_deploy_key'
      check 'deploy_key_deploy_keys_projects_attributes_0_can_push'
      click_button 'Save changes'

      expect(page).to have_content('updated_deploy_key')
      expect(page).to have_content('Write access allowed')
    end

    it 'edit an existing public deploy key to be writable' do
      project.deploy_keys << public_deploy_key
      visit project_settings_ci_cd_path(project)

      find('.deploy-key', text: public_deploy_key.title).find('.ic-pencil').click

      check 'deploy_key_deploy_keys_projects_attributes_0_can_push'
      click_button 'Save changes'

      expect(page).to have_content('public_deploy_key')
      expect(page).to have_content('Write access allowed')
    end

    it 'edit a deploy key from projects user has access to' do
      project2 = create(:project_empty_repo)
      project2.add_role(user, role)
      project2.deploy_keys << private_deploy_key

      visit project_settings_ci_cd_path(project)

      find('.js-deployKeys-tab-available_project_keys').click

      find('.deploy-key', text: private_deploy_key.title).find('.ic-pencil').click

      fill_in 'deploy_key_title', with: 'updated_deploy_key'
      click_button 'Save changes'

      find('.js-deployKeys-tab-available_project_keys').click

      expect(page).to have_content('updated_deploy_key')
    end

    it 'remove an existing deploy key' do
      project.deploy_keys << private_deploy_key
      visit project_settings_ci_cd_path(project)

      accept_confirm { find('.deploy-key', text: private_deploy_key.title).find('.ic-remove').click }

      expect(page).not_to have_content(private_deploy_key.title)
    end
  end
end
