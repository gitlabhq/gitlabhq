require 'spec_helper'

describe 'Profile account page' do
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

      page.within '.popup-dialog' do
        click_button 'Delete account'
      end

      expect(page).to have_content('Account scheduled for removal')
      expect(User.exists?(user.id)).to be_falsy
    end

    it 'shows invalid password flash message', :js do
      click_button 'Delete account'

      fill_in 'password', with: 'testing123'

      page.within '.popup-dialog' do
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

  describe 'when I reset private token' do
    before do
      visit profile_account_path
    end

    it 'resets private token' do
      previous_token = find("#private-token").value

      click_link('Reset private token')

      expect(find('#private-token').value).not_to eq(previous_token)
    end
  end

  describe 'when I reset RSS token' do
    before do
      visit profile_account_path
    end

    it 'resets RSS token' do
      previous_token = find("#rss-token").value

      click_link('Reset RSS token')

      expect(page).to have_content 'RSS token was successfully reset'
      expect(find('#rss-token').value).not_to eq(previous_token)
    end
  end

  describe 'when I reset incoming email token' do
    before do
      allow(Gitlab.config.incoming_email).to receive(:enabled).and_return(true)
      visit profile_account_path
    end

    it 'resets incoming email token' do
      previous_token = find('#incoming-email-token').value

      click_link('Reset incoming email token')

      expect(find('#incoming-email-token').value).not_to eq(previous_token)
    end
  end

  describe 'when I change my username' do
    before do
      visit profile_account_path
    end

    it 'changes my username' do
      fill_in 'user_username', with: 'new-username'

      click_button('Update username')

      expect(page).to have_content('new-username')
    end
  end
end
