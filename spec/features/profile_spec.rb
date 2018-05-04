require 'spec_helper'

describe 'Profile account page', :js do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'when I delete my account' do
    before do
      visit profile_account_path
    end

    it { expect(page).to have_content('Delete account') }

    it 'does not immediately delete the account' do
      click_button 'Delete account'

      expect(User.exists?(user.id)).to be_truthy
    end

    it 'deletes user', :js do
      click_button 'Delete account'

      fill_in 'password', with: '12345678'

      page.within '.modal' do
        click_button 'Delete account'
      end

      expect(page).to have_content('Account scheduled for removal')
      expect(User.exists?(user.id)).to be_falsy
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
      expect(page).to have_content("Your account is currently an owner in these groups: #{group.name}")
    end
  end

  describe 'when I reset RSS token' do
    before do
      visit profile_personal_access_tokens_path
    end

    it 'resets RSS token' do
      within('.rss-token-reset') do
        previous_token = find("#rss_token").value

        accept_confirm { click_link('reset it') }

        expect(find('#rss_token').value).not_to eq(previous_token)
      end

      expect(page).to have_content 'RSS token was successfully reset'
    end
  end

  describe 'when I reset incoming email token' do
    before do
      allow(Gitlab.config.incoming_email).to receive(:enabled).and_return(true)
      visit profile_personal_access_tokens_path
    end

    it 'resets incoming email token' do
      within('.incoming-email-token-reset') do
        previous_token = find('#incoming_email_token').value

        accept_confirm { click_link('reset it') }

        expect(find('#incoming_email_token').value).not_to eq(previous_token)
      end
    end
  end

  describe 'when I change my username' do
    before do
      visit profile_account_path
    end

    it 'changes my username' do
      fill_in 'username-change-input', with: 'new-username'

      page.find('[data-target="#username-change-confirmation-modal"]').click

      page.within('.modal') do
        find('.js-modal-primary-action').click
      end

      expect(page).to have_content('new-username')
    end
  end
end
