# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User Settings > SSH Keys', feature_category: :source_code_management do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'User adds a key', :js do
    before do
      visit user_settings_ssh_keys_path
    end

    it 'auto-populates the title' do
      click_button('Add new key')
      fill_in('Key', with: attributes_for(:key).fetch(:key))

      expect(page).to have_field("Title", with: "dummy@gitlab.com")
    end

    it 'saves the new key' do
      attrs = attributes_for(:key)

      click_button('Add new key')
      fill_in('Key', with: attrs[:key])
      fill_in('Title', with: attrs[:title])
      click_button('Add key')

      expect(page).to have_content(format(s_('Profiles|SSH Key: %{title}'), title: attrs[:title]))
      expect(page).to have_content(attrs[:key])
      expect(find_by_testid('breadcrumb-links').find('li:last-of-type')).to have_link(attrs[:title])
    end

    it 'shows a confirmable warning if the key begins with an algorithm name that is unsupported' do
      attrs = attributes_for(:key)

      click_button('Add new key')
      fill_in('Key', with: 'unsupported-ssh-rsa key')
      fill_in('Title', with: attrs[:title])
      click_button('Add key')

      expect(page).to have_selector('.js-add-ssh-key-validation-warning')

      find('.js-add-ssh-key-validation-confirm-submit').click

      expect(page).to have_content('Key is invalid')
    end

    context 'when only DSA and ECDSA keys are allowed' do
      before do
        forbidden = ApplicationSetting::FORBIDDEN_KEY_VALUE
        stub_application_setting(
          rsa_key_restriction: forbidden,
          ed25519_key_restriction: forbidden,
          ecdsa_sk_key_restriction: forbidden,
          ed25519_sk_key_restriction: forbidden
        )
      end

      it 'shows a validation error' do
        attrs = attributes_for(:key)

        click_button('Add new key')
        fill_in('Key', with: attrs[:key])
        fill_in('Title', with: attrs[:title])
        click_button('Add key')

        expect(page).to have_content('Key type is forbidden. Must be DSA or ECDSA')
      end
    end
  end

  it 'user sees their keys' do
    key = create(:key, user: user)
    visit user_settings_ssh_keys_path

    expect(page).to have_content(key.title)
  end

  def destroy_key(path, action, confirmation_button)
    visit path

    page.find("button[aria-label=\"#{action}\"]").click

    page.within('.modal') do
      page.click_button(confirmation_button)
    end

    expect(page).to have_content('Your SSH keys')
    within_testid('crud-count') do
      expect(page).to have_content('0')
    end
  end

  describe 'User removes a key', :js do
    let!(:key) { create(:key, user: user) }

    context 'with the key index' do
      it 'removes key' do
        destroy_key(user_settings_ssh_keys_path, 'Remove', 'Delete')
      end
    end

    context 'with its details page' do
      it 'removes key' do
        destroy_key(user_settings_ssh_keys_path(key), 'Remove', 'Delete')
      end
    end
  end

  describe 'User revokes a key', :js do
    context 'when a commit is signed using SSH key' do
      let!(:project) { create(:project, :repository) }
      let!(:key) { create(:key, user: user) }
      let!(:commit) { project.commit('ssh-signed-commit') }

      let!(:signature) do
        create(
          :ssh_signature,
          project: project,
          key: key,
          key_fingerprint_sha256: key.fingerprint_sha256,
          commit_sha: commit.sha
        )
      end

      before do
        project.add_developer(user)
      end

      it 'revoking the SSH key marks commits as unverified',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/455774' do
        visit project_commit_path(project, commit)
        wait_for_all_requests

        find('a.signature-badge', text: 'Verified').click

        within('.popover') do
          expect(page).to have_content("Verified commit")
          expect(page).to have_content("SSH key fingerprint: #{key.fingerprint_sha256}")
        end

        destroy_key(user_settings_ssh_keys_path, 'Revoke', 'Revoke')

        visit project_commit_path(project, commit)
        wait_for_all_requests

        find('a.signature-badge', text: 'Unverified').click

        within('.popover') do
          expect(page).to have_content("Unverified signature")
          expect(page).to have_content('This commit was signed with a key that was revoked.')
          expect(page).to have_content("SSH key fingerprint: #{signature.key_fingerprint_sha256}")
        end
      end
    end
  end
end
