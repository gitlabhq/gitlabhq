# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Settings > Repository settings' do
  let(:project) { create(:project_empty_repo) }
  let(:user) { create(:user) }
  let(:role) { :developer }

  before do
    project.add_role(user, role)
    sign_in(user)
  end

  context 'for developer' do
    let(:role) { :developer }

    it 'is not allowed to view' do
      visit project_settings_repository_path(project)

      expect(page.status_code).to eq(404)
    end
  end

  context 'for maintainer' do
    let(:role) { :maintainer }

    context 'Deploy Keys', :js do
      let(:private_deploy_key) { create(:deploy_key, title: 'private_deploy_key', public: false) }
      let(:public_deploy_key) { create(:another_deploy_key, title: 'public_deploy_key', public: true) }
      let(:new_ssh_key) { attributes_for(:key)[:key] }

      it 'get list of keys' do
        project.deploy_keys << private_deploy_key
        project.deploy_keys << public_deploy_key

        visit project_settings_repository_path(project)

        expect(page).to have_content('private_deploy_key')
        expect(page).to have_content('public_deploy_key')
      end

      it 'add a new deploy key' do
        visit project_settings_repository_path(project)

        fill_in 'deploy_key_title', with: 'new_deploy_key'
        fill_in 'deploy_key_key', with: new_ssh_key
        check 'deploy_key_deploy_keys_projects_attributes_0_can_push'
        click_button 'Add key'

        expect(page).to have_content('new_deploy_key')
        expect(page).to have_content('Write access allowed')
      end

      it 'edit an existing deploy key' do
        project.deploy_keys << private_deploy_key
        visit project_settings_repository_path(project)

        find('.deploy-key', text: private_deploy_key.title).find('.ic-pencil').click

        fill_in 'deploy_key_title', with: 'updated_deploy_key'
        check 'deploy_key_deploy_keys_projects_attributes_0_can_push'
        click_button 'Save changes'

        expect(page).to have_content('updated_deploy_key')
        expect(page).to have_content('Write access allowed')
      end

      it 'edit a deploy key from projects user has access to' do
        project2 = create(:project_empty_repo)
        project2.add_role(user, role)
        project2.deploy_keys << private_deploy_key

        visit project_settings_repository_path(project)

        find('.js-deployKeys-tab-available_project_keys').click

        find('.deploy-key', text: private_deploy_key.title).find('.ic-pencil').click

        fill_in 'deploy_key_title', with: 'updated_deploy_key'
        click_button 'Save changes'

        find('.js-deployKeys-tab-available_project_keys').click

        expect(page).to have_content('updated_deploy_key')
      end

      it 'remove an existing deploy key' do
        project.deploy_keys << private_deploy_key
        visit project_settings_repository_path(project)

        accept_confirm { find('.deploy-key', text: private_deploy_key.title).find('.ic-remove').click }

        expect(page).not_to have_content(private_deploy_key.title)
      end
    end

    context 'Deploy tokens' do
      let!(:deploy_token) { create(:deploy_token, projects: [project]) }

      before do
        stub_container_registry_config(enabled: true)
        visit project_settings_repository_path(project)
      end

      it 'view deploy tokens' do
        within('.deploy-tokens') do
          expect(page).to have_content(deploy_token.name)
          expect(page).to have_content('read_repository')
          expect(page).to have_content('read_registry')
        end
      end

      it 'add a new deploy token' do
        fill_in 'deploy_token_name', with: 'new_deploy_key'
        fill_in 'deploy_token_expires_at', with: (Date.today + 1.month).to_s
        fill_in 'deploy_token_username', with: 'deployer'
        check 'deploy_token_read_repository'
        check 'deploy_token_read_registry'
        click_button 'Create deploy token'

        expect(page).to have_content('Your new project deploy token has been created')

        within('.created-deploy-token-container') do
          expect(page).to have_selector("input[name='deploy-token-user'][value='deployer']")
          expect(page).to have_selector("input[name='deploy-token'][readonly='readonly']")
        end
      end
    end

    context 'remote mirror settings' do
      let(:user2) { create(:user) }

      before do
        project.add_maintainer(user2)

        visit project_settings_repository_path(project)
      end

      it 'shows push mirror settings', :js do
        expect(page).to have_selector('#mirror_direction')
      end

      it 'creates a push mirror that mirrors all branches', :js do
        expect(find('.js-mirror-protected-hidden', visible: false).value).to eq('0')

        fill_in 'url', with: 'ssh://user@localhost/project.git'
        select 'SSH public key', from: 'Authentication method'

        select_direction

        Sidekiq::Testing.fake! do
          click_button 'Mirror repository'
        end

        project.reload

        expect(page).to have_content('Mirroring settings were successfully updated')
        expect(project.remote_mirrors.first.only_protected_branches).to eq(false)
      end

      it 'creates a push mirror that only mirrors protected branches', :js do
        find('#only_protected_branches').click

        expect(find('.js-mirror-protected-hidden', visible: false).value).to eq('1')

        fill_in 'url', with: 'ssh://user@localhost/project.git'
        select 'SSH public key', from: 'Authentication method'

        select_direction

        Sidekiq::Testing.fake! do
          click_button 'Mirror repository'
        end

        project.reload

        expect(page).to have_content('Mirroring settings were successfully updated')
        expect(project.remote_mirrors.first.only_protected_branches).to eq(true)
      end

      it 'generates an SSH public key on submission', :js do
        fill_in 'url', with: 'ssh://user@localhost/project.git'
        select 'SSH public key', from: 'Authentication method'

        select_direction

        Sidekiq::Testing.fake! do
          click_button 'Mirror repository'
        end

        expect(page).to have_content('Mirroring settings were successfully updated')
        expect(page).to have_selector('[title="Copy SSH public key"]')
      end

      def select_direction(direction = 'push')
        direction_select = find('#mirror_direction')

        # In CE, this select box is disabled, but in EE, it is enabled
        if direction_select.disabled?
          expect(direction_select.value).to eq(direction)
        else
          direction_select.select(direction.capitalize)
        end
      end
    end

    context 'repository cleanup settings' do
      let(:object_map_file) { Rails.root.join('spec', 'fixtures', 'bfg_object_map.txt') }

      it 'uploads an object map file', :js do
        visit project_settings_repository_path(project)

        expect(page).to have_content('Repository cleanup')

        page.within('#cleanup') do
          attach_file('project[bfg_object_map]', object_map_file, visible: false)

          Sidekiq::Testing.fake! do
            click_button 'Start cleanup'
          end
        end

        expect(page).to have_content('Repository cleanup has started')
        expect(RepositoryCleanupWorker.jobs.count).to eq(1)
      end
    end

    context 'with an existing mirror', :js do
      let(:mirrored_project) { create(:project, :repository, :remote_mirror) }

      before do
        mirrored_project.add_maintainer(user)

        visit project_settings_repository_path(mirrored_project)
      end

      it 'delete remote mirrors' do
        expect(mirrored_project.remote_mirrors.count).to eq(1)

        find('.js-delete-mirror').click
        wait_for_requests

        expect(mirrored_project.remote_mirrors.count).to eq(0)
      end
    end

    it 'shows a disabled mirror' do
      create(:remote_mirror, project: project, enabled: false)

      visit project_settings_repository_path(project)

      mirror = find('.qa-mirrored-repository-row')

      expect(mirror).to have_selector('.qa-delete-mirror')
      expect(mirror).to have_selector('.qa-disabled-mirror-badge')
      expect(mirror).not_to have_selector('.qa-update-now-button')
    end
  end
end
