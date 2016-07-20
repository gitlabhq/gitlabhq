require 'spec_helper'

feature 'Users', feature: true, js: true do
  let(:user) { create(:user, username: 'user1', name: 'User 1', email: 'user1@gitlab.com') }

  scenario 'GET /users/sign_in creates a new user account' do
    visit new_user_session_path
    fill_in 'new_user_name',     with: 'Name Surname'
    fill_in 'new_user_username', with: 'Great'
    fill_in 'new_user_email',    with: 'name@mail.com'
    fill_in 'new_user_password', with: 'password1234'
    expect { click_button 'Sign up' }.to change { User.count }.by(1)
  end

  scenario 'Successful user signin invalidates password reset token' do
    expect(user.reset_password_token).to be_nil

    visit new_user_password_path
    fill_in 'user_email', with: user.email
    click_button 'Reset password'

    user.reload
    expect(user.reset_password_token).not_to be_nil

    login_with(user)
    expect(current_path).to eq root_path

    user.reload
    expect(user.reset_password_token).to be_nil
  end

  scenario 'Should show one error if email is already taken' do
    visit new_user_session_path
    fill_in 'new_user_name',     with: 'Another user name'
    fill_in 'new_user_username', with: 'anotheruser'
    fill_in 'new_user_email',    with: user.email
    fill_in 'new_user_password', with: '12341234'
    expect { click_button 'Sign up' }.to change { User.count }.by(0)
    expect(page).to have_text('Email has already been taken')
    expect(number_of_errors_on_page(page)).to be(1), 'errors on page:\n #{errors_on_page page}'
  end

  feature 'username validation' do
    include WaitForAjax
    let(:loading_icon) { '.fa.fa-spinner' }
    let(:username_input) { 'new_user_username' }

    before(:each) do
      visit new_user_session_path
      @username_field = find '.username'
    end

    scenario 'shows an error icon if the username already exists' do
      fill_in username_input, with: user.username
      expect(@username_field).to have_css loading_icon
      wait_for_ajax
      expect(@username_field).to have_css '.fa.error'
    end

    scenario 'shows a success icon if the username is available' do
      fill_in username_input, with: 'new-user'
      expect(@username_field).to have_css loading_icon
      wait_for_ajax
      expect(@username_field).to have_css '.fa.success'
    end
  end

  def errors_on_page(page)
    page.find('#error_explanation').find('ul').all('li').map{ |item| item.text }.join("\n")
  end

  def number_of_errors_on_page(page)
    page.find('#error_explanation').find('ul').all('li').count
  end
end
