require 'spec_helper'

feature 'Signup on EE' do
  context 'for Gitlab.com' do
    before do
      expect(Gitlab).to receive(:com?).and_return(true).at_least(:once)
    end

    context 'when the user checks the opt-in to email updates box' do
      it 'creates the user and sets the email_opted_in field truthy' do
        user = build(:user)

        visit root_path

        fill_in 'new_user_name',                with: user.name
        fill_in 'new_user_username',            with: user.username
        fill_in 'new_user_email',               with: user.email
        fill_in 'new_user_email_confirmation',  with: user.email
        fill_in 'new_user_password',            with: user.password
        check   'new_user_email_opted_in'
        click_button "Register"

        user = User.find_by_username!(user.username)
        expect(user.email_opted_in).to be_truthy
      end
    end

    context 'when the user does not check the opt-in to email updates box' do
      it 'creates the user and sets the email_opted_in field falsey' do
        user = build(:user)

        visit root_path

        fill_in 'new_user_name',                with: user.name
        fill_in 'new_user_username',            with: user.username
        fill_in 'new_user_email',               with: user.email
        fill_in 'new_user_email_confirmation',  with: user.email
        fill_in 'new_user_password',            with: user.password
        click_button "Register"

        user = User.find_by_username!(user.username)
        expect(user.email_opted_in).to be_falsey
      end
    end
  end

  context 'not for Gitlab.com' do
    before do
      expect(Gitlab).to receive(:com?).and_return(false).at_least(:once)
    end

    it 'does not have a opt-in checkbox, it creates the user and sets email_opted_in to falsey' do
      user = build(:user)

      visit root_path

      expect(page).not_to have_selector("[name='new_user_email_opted_in']")

      fill_in 'new_user_name',                with: user.name
      fill_in 'new_user_username',            with: user.username
      fill_in 'new_user_email',               with: user.email
      fill_in 'new_user_email_confirmation',  with: user.email
      fill_in 'new_user_password',            with: user.password
      click_button "Register"

      user = User.find_by_username!(user.username)
      expect(user.email_opted_in).to be_falsey
    end
  end
end
