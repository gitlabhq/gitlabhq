# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Account', :js, feature_category: :user_profile do
  let(:user) { create(:user, username: 'foo') }

  before do
    sign_in(user)
  end

  describe 'Service sign-in' do
    context 'when an identity does not exist' do
      before do
        allow(Devise).to receive_messages(omniauth_configs: { google_oauth2: {} })
      end

      it 'allows the user to connect' do
        visit profile_account_path

        expect(page).to have_link('Connect Google', href: '/users/auth/google_oauth2')
      end
    end

    context 'when an identity already exists' do
      before do
        allow(Devise).to receive_messages(omniauth_configs: { twitter: {}, saml: {} })

        create(:identity, user: user, provider: :twitter)
        create(:identity, user: user, provider: :saml)

        visit profile_account_path
      end

      it 'allows the user to disconnect when there is an existing identity' do
        expect(page).to have_link('Disconnect Twitter', href: '/-/profile/account/unlink?provider=twitter')
      end

      it 'shows active for a provider that is not allowed to unlink' do
        expect(page).to have_content('Saml Active')
      end
    end
  end

  describe 'Change username' do
    let(:new_username) { 'bar' }
    let(:new_user_path) { "/#{new_username}" }
    let(:old_user_path) { "/#{user.username}" }

    it 'the user is accessible via the new path' do
      update_username(new_username)
      visit new_user_path
      expect(page).to have_current_path(new_user_path, ignore_query: true)
      expect(find_by_testid('user-profile-header')).to have_content(new_username)
    end

    it 'the old user path redirects to the new path' do
      update_username(new_username)
      visit old_user_path
      expect(page).to have_current_path(new_user_path, ignore_query: true)
      expect(find_by_testid('user-profile-header')).to have_content(new_username)
    end

    context 'with a project' do
      let!(:project) { create(:project, namespace: user.namespace) }
      let(:new_project_path) { "/#{new_username}/#{project.path}" }
      let(:old_project_path) { "/#{user.username}/#{project.path}" }

      before(:context) do
        TestEnv.clean_test_path
      end

      after do
        TestEnv.clean_test_path
      end

      it 'the project is accessible via the new path' do
        update_username(new_username)
        visit new_project_path
        expect(page).to have_current_path(new_project_path, ignore_query: true)
        expect(find_by_testid('breadcrumb-links')).to have_content(user.name)
      end

      it 'the old project path redirects to the new path' do
        update_username(new_username)
        visit old_project_path
        expect(page).to have_current_path(new_project_path, ignore_query: true)
        expect(find_by_testid('breadcrumb-links')).to have_content(user.name)
      end
    end
  end

  describe 'Delete account' do
    before do
      create_list(:project, number_of_projects, namespace: user.namespace)
      visit profile_account_path
    end

    context 'when there are no personal projects' do
      let(:number_of_projects) { 0 }

      it 'does not show personal projects removal message' do
        expect(page).not_to have_content(/\d personal projects? will be removed and cannot be restored/)
      end
    end

    context 'when one personal project exists' do
      let(:number_of_projects) { 1 }

      it 'does show personal project removal message' do
        expect(page).to have_content('1 personal project will be removed and cannot be restored')
      end
    end

    context 'when more than one personal projects exists' do
      let(:number_of_projects) { 3 }

      it 'shows pluralized personal project removal message' do
        expect(page).to have_content('3 personal projects will be removed and cannot be restored')
      end
    end
  end
end

def update_username(new_username)
  allow(user.namespace).to receive(:move_dir)
  visit profile_account_path

  fill_in 'username-change-input', with: new_username

  find_by_testid('username-change-confirmation-modal').click

  page.within('.modal') do
    find('.js-modal-action-primary').click
  end

  wait_for_requests
end
