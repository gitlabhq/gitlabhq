require 'spec_helper'

feature 'Signup on EE' do
  let(:user_attrs) { attributes_for(:user) }

  context 'for Gitlab.com' do
    before do
      expect(Gitlab).to receive(:com?).and_return(true).at_least(:once)
    end

    context 'when the user checks the opt-in to email updates box' do
      it 'creates the user and sets the email_opted_in field truthy' do
        visit root_path

        fill_in 'new_user_name',                with: user_attrs[:name]
        fill_in 'new_user_username',            with: user_attrs[:username]
        fill_in 'new_user_email',               with: user_attrs[:email]
        fill_in 'new_user_email_confirmation',  with: user_attrs[:email]
        fill_in 'new_user_password',            with: user_attrs[:password]
        check   'new_user_email_opted_in'
        click_button "Register"

        user = User.find_by_username!(user_attrs[:username])
        expect(user.email_opted_in).to be_truthy
        expect(user.email_opted_in_ip).to be_present
        expect(user.email_opted_in_source).to eq('GitLab.com')
        expect(user.email_opted_in_at).not_to be_nil
      end
    end

    context 'when the user does not check the opt-in to email updates box' do
      it 'creates the user and sets the email_opted_in field falsey' do
        visit root_path

        fill_in 'new_user_name',                with: user_attrs[:name]
        fill_in 'new_user_username',            with: user_attrs[:username]
        fill_in 'new_user_email',               with: user_attrs[:email]
        fill_in 'new_user_email_confirmation',  with: user_attrs[:email]
        fill_in 'new_user_password',            with: user_attrs[:password]
        click_button "Register"

        user = User.find_by_username!(user_attrs[:username])
        expect(user.email_opted_in).to be_falsey
        expect(user.email_opted_in_ip).to be_blank
        expect(user.email_opted_in_source).to be_blank
        expect(user.email_opted_in_at).to be_nil
      end
    end
  end

  context 'not for Gitlab.com' do
    before do
      expect(Gitlab).to receive(:com?).and_return(false).at_least(:once)
    end

    it 'does not have a opt-in checkbox, it creates the user and sets email_opted_in to falsey' do
      visit root_path

      expect(page).not_to have_selector("[name='new_user_email_opted_in']")

      fill_in 'new_user_name',                with: user_attrs[:name]
      fill_in 'new_user_username',            with: user_attrs[:username]
      fill_in 'new_user_email',               with: user_attrs[:email]
      fill_in 'new_user_email_confirmation',  with: user_attrs[:email]
      fill_in 'new_user_password',            with: user_attrs[:password]
      click_button "Register"

      user = User.find_by_username!(user_attrs[:username])
      expect(user.email_opted_in).to be_falsey
      expect(user.email_opted_in_ip).to be_blank
      expect(user.email_opted_in_source).to be_blank
      expect(user.email_opted_in_at).to be_nil
    end
  end
end
