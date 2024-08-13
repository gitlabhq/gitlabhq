# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > Repository settings', feature_category: :source_code_management do
  include Features::MirroringHelpers

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

    context 'Deploy tokens', :js do
      let!(:deploy_token) { create(:deploy_token, projects: [project]) }

      before do
        stub_container_registry_config(enabled: true)
      end

      it_behaves_like 'a deploy token in settings' do
        let(:entity_type) { 'project' }
        let(:page_path) { project_settings_repository_path(project) }
      end
    end

    context 'Repository maintenance', :js do
      before do
        visit project_settings_repository_path(project)
      end

      it 'does not render remove blobs section' do
        expect(page).not_to have_content('Remove blobs')
      end

      it 'does not render redact text section' do
        expect(page).not_to have_content('Redact text')
      end
    end

    context 'Branch rules', :js do
      it 'renders branch rules settings' do
        visit project_settings_repository_path(project)
        expect(page).to have_content('Branch rules')
      end
    end

    context 'Deploy keys', :js do
      let_it_be(:private_deploy_key) { create(:deploy_key, title: 'private_deploy_key', public: false) }
      let_it_be(:public_deploy_key) { create(:another_deploy_key, title: 'public_deploy_key', public: true) }

      let(:new_ssh_key) { attributes_for(:key)[:key] }

      around do |example|
        travel_to Time.zone.local(2022, 3, 1, 1, 0, 0) { example.run }
      end

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
        expect(page).to have_content('Grant write permissions to this key')
      end

      it 'add a new deploy key with expiration' do
        one_month = Time.zone.local(2022, 4, 1, 1, 0, 0)
        visit project_settings_repository_path(project)

        fill_in 'deploy_key_title', with: 'new_deploy_key_with_expiry'
        fill_in 'deploy_key_key', with: new_ssh_key
        fill_in 'deploy_key_expires_at', with: one_month.to_s
        check 'deploy_key_deploy_keys_projects_attributes_0_can_push'
        click_button 'Add key'

        expect(page).to have_content('new_deploy_key_with_expiry')
        expect(page).to have_content('in 1 month')
        expect(page).to have_content('Grant write permissions to this key')
      end

      it 'edit an existing deploy key' do
        project.deploy_keys << private_deploy_key
        visit project_settings_repository_path(project)

        within('.deploy-key', text: private_deploy_key.title) do
          find_by_testid('pencil-icon').click
        end

        fill_in 'deploy_key_title', with: 'updated_deploy_key'
        check 'deploy_key_deploy_keys_projects_attributes_0_can_push'
        click_button 'Save changes'

        expect(page).to have_content('updated_deploy_key')
        expect(page).to have_content('Grant write permissions to this key')
      end

      it 'edit an existing public deploy key to be writable' do
        project.deploy_keys << public_deploy_key
        visit project_settings_repository_path(project)

        within('.deploy-key', text: public_deploy_key.title) do
          find_by_testid('pencil-icon').click
        end

        check 'deploy_key_deploy_keys_projects_attributes_0_can_push'
        click_button 'Save changes'

        expect(page).to have_content('public_deploy_key')
        expect(page).to have_content('Grant write permissions to this key')
      end

      it 'edit a deploy key from projects user has access to' do
        project2 = create(:project_empty_repo)
        project2.add_role(user, role)
        project2.deploy_keys << private_deploy_key

        visit project_settings_repository_path(project)

        find('.js-deployKeys-tab-available_project_keys').click

        within('.deploy-key', text: private_deploy_key.title) do
          find_by_testid('pencil-icon').click
        end

        fill_in 'deploy_key_title', with: 'updated_deploy_key'
        click_button 'Save changes'

        find('.js-deployKeys-tab-available_project_keys').click

        expect(page).to have_content('updated_deploy_key')
      end

      it 'remove an existing deploy key' do
        project.deploy_keys << private_deploy_key
        visit project_settings_repository_path(project)

        click_button 'Remove'
        click_button 'Remove deploy key'

        expect(page).not_to have_content(private_deploy_key.title)
      end
    end

    context 'remote mirror settings' do
      let(:ssh_url) { 'ssh://user@localhost/project.git' }

      before do
        visit project_settings_repository_path(project)
        click_button 'Add new'
      end

      it 'shows push mirror settings', :js do
        expect(page).to have_selector('#mirror_direction')
      end

      it 'creates a push mirror that mirrors all branches', :js do
        wait_for_mirror_field_javascript('protected', '0')
        fill_and_wait_for_mirror_url_javascript('url', ssh_url)

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

        wait_for_mirror_field_javascript('protected', '1')
        fill_and_wait_for_mirror_url_javascript('url', ssh_url)

        select 'SSH public key', from: 'Authentication method'
        select_direction

        Sidekiq::Testing.fake! do
          click_button 'Mirror repository'
        end

        project.reload
        expect(page).to have_content('Mirroring settings were successfully updated')
        expect(project.remote_mirrors.first.only_protected_branches).to eq(true)
      end

      it 'creates a push mirror that keeps divergent refs', :js do
        select_direction

        fill_and_wait_for_mirror_url_javascript('url', ssh_url)

        fill_in 'Password', with: 'password'
        check 'Keep divergent refs'

        Sidekiq::Testing.fake! do
          click_button 'Mirror repository'
        end

        # TODO: The following line is skipped because a toast with
        # "An error occurred while loading branch rules. Please try again."
        # shows up right after which hides the below message. It is causing flakiness.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/383717#note_1185091998

        # expect(page).to have_content('Mirroring settings were successfully updated')
        expect(project.reload.remote_mirrors.first.keep_divergent_refs).to eq(true)
      end

      it 'generates an SSH public key on submission', :js do
        fill_and_wait_for_mirror_url_javascript('url', ssh_url)

        select 'SSH public key', from: 'Authentication method'

        select_direction

        Sidekiq::Testing.fake! do
          click_button 'Mirror repository'
        end

        # TODO: The following line is skipped because a toast with
        # "An error occurred while loading branch rules. Please try again."
        # shows up right after which hides the below message. It is causing flakiness.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/383717#note_1185091998

        # expect(page).to have_content('Mirroring settings were successfully updated')
        expect(page).to have_selector('[title="Copy SSH public key"]')
      end

      context 'when project mirroring is disabled' do
        before do
          stub_application_setting(mirror_available: false)
          visit project_settings_repository_path(project)
        end

        it 'hides remote mirror settings' do
          expect(find_by_testid('mirroring-repositories-settings-content')).not_to have_selector('form')
          expect(page).to have_content('Mirror settings are only available to GitLab administrators.')
        end
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

      mirror = find('.rspec-mirrored-repository-row')

      expect(mirror).to have_selector('.rspec-delete-mirror')
      expect(mirror).to have_selector('.rspec-disabled-mirror-badge')
      expect(mirror).not_to have_selector('.rspec-update-now-button')
    end
  end

  context 'for admin' do
    shared_examples_for 'shows mirror settings' do
      it 'shows mirror settings' do
        expect(find_by_testid('mirroring-repositories-settings-content')).to have_selector('form')
        expect(page).not_to have_content('Changing mirroring setting is disabled for non-admin users.')
      end
    end

    before do
      stub_application_setting(mirror_available: mirror_available)
      user.update!(admin: true)
      visit project_settings_repository_path(project)
    end

    context 'when project mirroring is enabled', :enable_admin_mode do
      let(:mirror_available) { true }

      include_examples 'shows mirror settings'
    end

    context 'when project mirroring is disabled', :enable_admin_mode do
      let(:mirror_available) { false }

      include_examples 'shows mirror settings'
    end

    context 'Repository maintenance', :enable_admin_mode do
      let(:mirror_available) { false }

      it 'renders remove blobs section' do
        expect(page).to have_content('Remove blobs')
      end

      it 'renders redact text section' do
        expect(page).to have_content('Redact text')
      end
    end
  end
end
