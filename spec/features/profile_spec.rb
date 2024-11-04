# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile account page', :js, feature_category: :user_profile do
  include Spec::Support::Helpers::ModalHelpers

  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'when I delete my account' do
    before do
      visit profile_account_path

      # Scroll page to the bottom to make Delete account button visible
      execute_script('window.scrollTo(0, document.body.scrollHeight)')
    end

    it { expect(page).to have_content('Delete account') }

    it 'does not immediately delete the account' do
      click_button 'Delete account'

      expect(User.exists?(user.id)).to be_truthy
    end

    it 'deletes user', :js, :sidekiq_inline do
      click_button 'Delete account'

      fill_in 'password', with: user.password

      page.within '.modal' do
        click_button 'Delete account'
      end

      expect(page).to have_content('Account scheduled for removal')
      expect(
        Users::GhostUserMigration.where(user: user, initiator_user: user)
      ).to be_exists
    end

    it 'shows invalid password flash message', :js do
      click_button 'Delete account'

      fill_in 'password', with: 'testing123'

      page.within '.modal' do
        click_button 'Delete account'
      end

      expect(page).to have_content('Invalid password')
    end

    it 'does not show delete button when user owns a group' do
      group = create(:group)
      group.add_owner(user)

      visit profile_account_path

      expect(page).not_to have_button('Delete account')
      expect(page).to have_content("Your account is currently the sole owner in the following:")
      expect(page).to have_link(group.name, href: group.web_url)
    end

    it 'does not show delete button when user owns an organization and feature flag ui_for_organizations is enabled' do
      stub_feature_flags(ui_for_organizations: true)
      organization = create(:organization)
      create(:organization_owner, user: user, organization: organization)

      visit profile_account_path

      expect(page).not_to have_button('Delete account')
      expect(page).to have_content("Your account is currently the sole owner in the following:")
      expect(page).to have_link(organization.name, href: organization.web_url)
    end
  end

  describe 'when I reset my feed token' do
    context 'when resetting succeeds' do
      it 'allows resetting of feed token' do
        visit user_settings_personal_access_tokens_path

        previous_token = ''

        within_testid('feed-token-container') do
          previous_token = find_field('Feed token').value

          click_link('reset this token')
        end

        accept_gl_confirm

        expect(page).to have_content('Feed token was successfully reset')

        within_testid('feed-token-container') do
          click_button('Click to reveal')

          expect(find_field('Feed token').value).not_to eq(previous_token)
        end
      end
    end

    context 'when resetting fails' do
      before do
        allow_next_instance_of(Users::UpdateService) do |service|
          allow(service).to receive(:execute).and_return({ status: :error })
        end
      end

      it 'shows an error and the old feed token' do
        visit user_settings_personal_access_tokens_path

        previous_token = ''

        within_testid('feed-token-container') do
          previous_token = find_field('Feed token').value

          click_link('reset this token')
        end

        accept_gl_confirm

        expect(page).to have_content('Feed token could not be reset')

        within_testid('feed-token-container') do
          click_button('Click to reveal')

          expect(find_field('Feed token').value).to eq(previous_token)
        end
      end
    end
  end

  it 'allows resetting of incoming email token' do
    allow(Gitlab.config.incoming_email).to receive(:enabled).and_return(true)

    visit user_settings_personal_access_tokens_path

    previous_token = ''

    within_testid('incoming-email-token-container') do
      previous_token = find_field('Incoming email token').value

      click_link('reset this token')
    end

    accept_gl_confirm

    within_testid('incoming-email-token-container') do
      click_button('Click to reveal')

      expect(find_field('Incoming email token').value).not_to eq(previous_token)
    end
  end

  describe 'when I change my username' do
    before do
      visit profile_account_path
    end

    it 'changes my username' do
      fill_in 'username-change-input', with: 'new-username'

      find_by_testid('username-change-confirmation-modal').click

      page.within('.modal') do
        find('.js-modal-action-primary').click
      end

      expect(page).to have_content('new-username')
    end
  end
end
