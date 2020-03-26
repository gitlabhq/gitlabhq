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

    context 'remote mirror settings' do
      before do
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

      context 'when project mirroring is disabled' do
        before do
          stub_application_setting(mirror_available: false)
          visit project_settings_repository_path(project)
        end

        it 'hides remote mirror settings' do
          expect(page.find('.project-mirror-settings')).not_to have_selector('form')
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
        expect(page.find('.project-mirror-settings')).to have_selector('form')
        expect(page).not_to have_content('Changing mirroring setting is disabled for non-admin users.')
      end
    end

    before do
      stub_application_setting(mirror_available: mirror_available)
      user.update!(admin: true)
      visit project_settings_repository_path(project)
    end

    context 'when project mirroring is enabled' do
      let(:mirror_available) { true }

      include_examples 'shows mirror settings'
    end

    context 'when project mirroring is disabled' do
      let(:mirror_available) { false }

      include_examples 'shows mirror settings'
    end
  end
end
