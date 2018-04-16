require 'spec_helper'

feature 'Project mirror', :js do
  include ReactiveCachingHelpers

  let(:project) { create(:project, :mirror, :import_finished, :repository, creator: user, name: 'Victorialand') }
  let(:user) { create(:user) }

  describe 'On a project' do
    before do
      project.add_master(user)
      sign_in user
    end

    context 'unlicensed' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'returns 404' do
        reqs = inspect_requests do
          visit project_mirror_path(project)
        end

        expect(reqs.first.status_code).to eq(404)
      end
    end

    context 'with Update now button' do
      let(:timestamp) { Time.now }

      before do
        project.mirror_data.update_attributes(next_execution_timestamp: timestamp + 10.minutes)
      end

      context 'when able to force update' do
        it 'forces import' do
          project.update_attributes(mirror_last_update_at: timestamp - 8.minutes)

          expect_any_instance_of(EE::Project).to receive(:force_import_job!)

          Timecop.freeze(timestamp) do
            visit project_mirror_path(project)
          end

          Sidekiq::Testing.fake! { click_link('Update Now') }
        end
      end

      context 'when unable to force update' do
        it 'does not force import' do
          project.update_attributes(mirror_last_update_at: timestamp - 3.minutes)

          expect_any_instance_of(EE::Project).not_to receive(:force_import_job!)

          Timecop.freeze(timestamp) do
            visit project_mirror_path(project)
          end

          expect(page).to have_content('Update Now')
          expect(page).to have_selector('.btn.disabled')
        end
      end
    end
  end

  describe 'configuration' do
    # Start from a project with no mirroring set up
    let(:project) { create(:project, :repository, creator: user) }
    let(:import_data) { project.import_data(true) }

    before do
      project.add_master(user)
      sign_in(user)
    end

    describe 'password authentication' do
      it 'can be set up' do
        visit project_settings_repository_path(project)

        page.within('.project-mirror-settings') do
          fill_in 'Git repository URL', with: 'http://user@example.com'
          select('Pull', from: 'Mirror direction')
          fill_in 'Password', with: 'foo'
          click_without_sidekiq 'Mirror repository'
        end

        expect(page).to have_content('Mirroring settings were successfully updated')

        project.reload
        expect(project.mirror?).to be_truthy
        expect(import_data.auth_method).to eq('password')
        expect(project.import_url).to eq('http://user:foo@example.com')
      end

      it 'can be changed to unauthenticated' do
        project.update!(import_url: 'http://user:password@example.com')

        visit project_settings_repository_path(project)

        page.within('.project-mirror-settings') do
          fill_in 'Git repository URL', with: 'http://2.example.com'
          select('Pull', from: 'Mirror direction')
          fill_in 'Password', with: ''
          click_without_sidekiq 'Mirror repository'
        end

        expect(page).to have_content('Mirroring settings were successfully updated')

        project.reload
        expect(import_data.auth_method).to eq('password')
        expect(project.import_url).to eq('http://2.example.com')
      end
    end

    describe 'SSH public key authentication' do
      it 'can be set up' do
        visit project_settings_repository_path(project)

        page.within('.project-mirror-settings') do
          fill_in 'Git repository URL', with: 'ssh://user@example.com'
          select('Pull', from: 'Mirror direction')
          select 'SSH public key', from: 'Authentication method'

          # Generates an SSH public key with an asynchronous PUT and displays it
          wait_for_requests

          expect(import_data.ssh_public_key).not_to be_nil
          expect(page).to have_content(import_data.ssh_public_key)

          click_without_sidekiq 'Mirror repository'

          fill_in 'Git repository URL', with: 'ssh://user@example.com'
          select('Pull', from: 'Mirror direction')
        end

        # We didn't set any host keys
        expect(page).to have_content('Mirroring settings were successfully updated')
        expect(page).not_to have_content('Verified by')

        project.reload
        import_data.reload
        expect(project.mirror?).to be_truthy
        expect(project.username_only_import_url).to eq('ssh://user@example.com')
        expect(import_data.auth_method).to eq('ssh_public_key')
        expect(import_data.password).to be_blank

        first_key = import_data.ssh_public_key
        expect(page).to have_content(first_key)

        # Check regenerating the public key works
        accept_confirm { click_without_sidekiq 'Regenerate key' }
        wait_for_requests

        page.within('.project-mirror-settings') do
          fill_in 'Git repository URL', with: 'ssh://user@example.com'
          select('Pull', from: 'Mirror direction')
        end

        expect(page).not_to have_content(first_key)
        expect(page).to have_content(import_data.reload.ssh_public_key)
      end
    end

    describe 'host key management', :use_clean_rails_memory_store_caching do
      let(:key) { Gitlab::SSHPublicKey.new(SSHKeygen.generate) }
      let(:cache) { SshHostKey.new(project: project, url: "ssh://example.com:22") }

      it 'fills fingerprints and host keys when detecting' do
        stub_reactive_cache(cache, known_hosts: key.key_text)

        visit project_settings_repository_path(project)

        page.within('.project-mirror-settings') do
          fill_in 'Git repository URL', with: 'ssh://example.com'
          select('Pull', from: 'Mirror direction')
          click_on 'Detect host keys'
          wait_for_requests

          expect(page).to have_content(key.fingerprint)

          click_on 'Input host keys manually'

          expect(page).to have_field('SSH host keys', with: key.key_text)
        end
      end

      it 'displays error if detection fails' do
        stub_reactive_cache(cache, error: 'Some error text here')

        visit project_settings_repository_path(project)

        page.within('.project-mirror-settings') do
          fill_in 'Git repository URL', with: 'ssh://example.com'
          select('Pull', from: 'Mirror direction')
          click_on 'Detect host keys'
          wait_for_requests
        end

        # Appears in the flash
        expect(page).to have_content('Some error text here')
      end

      it 'allows manual host keys entry' do
        visit project_settings_repository_path(project)

        page.within('.project-mirror-settings') do
          fill_in 'Git repository URL', with: 'ssh://example.com'
          select('Pull', from: 'Mirror direction')
          click_on 'Input host keys manually'
          fill_in 'SSH host keys', with: "example.com #{key.key_text}"
          click_without_sidekiq 'Mirror repository'

          fill_in 'Git repository URL', with: 'ssh://example.com'
          select('Pull', from: 'Mirror direction')

          expect(page).to have_content(key.fingerprint)
          expect(page).to have_content("Verified by #{h(user.name)} less than a minute ago")
        end
      end
    end

    describe 'authentication methods' do
      it 'shows SSH related fields for an SSH URL' do
        visit project_settings_repository_path(project)

        page.within('.project-mirror-settings') do
          fill_in 'Git repository URL', with: 'ssh://example.com'
          select('Pull', from: 'Mirror direction')

          expect(page).to have_select('Authentication method')

          # SSH can use password authentication but needs host keys
          expect(page).to have_field('Password')
          select 'Password', from: 'Authentication method'
          expect(page).to have_button('Detect host keys')
          expect(page).to have_button('Input host keys manually')

          # SSH public key authentication also needs host keys but no password
          select 'SSH public key', from: 'Authentication method'
          expect(page).not_to have_field('Password')
          expect(page).to have_button('Detect host keys')
          expect(page).to have_button('Input host keys manually')
        end
      end

      it 'hides SSH-related fields for a HTTP URL' do
        visit project_settings_repository_path(project)

        page.within('.project-mirror-settings') do
          fill_in 'Git repository URL', with: 'https://example.com'
          select('Pull', from: 'Mirror direction')

          # HTTPS can't use public key authentication and doesn't need host keys
          expect(page).to have_field('Password')
          expect(page).not_to have_select('Authentication method')
          expect(page).not_to have_button('Detect host keys')
          expect(page).not_to have_button('Input host keys manually')
        end
      end
    end

    def click_without_sidekiq(*args)
      Sidekiq::Testing.fake! { click_on(*args) }
    end
  end
end
