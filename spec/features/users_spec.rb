require 'spec_helper'

feature 'Users' do
  around do |ex|
    old_url_options = Rails.application.routes.default_url_options
    Rails.application.routes.default_url_options = { host: 'example.foo' }
    ex.run
    Rails.application.routes.default_url_options = old_url_options
  end

  scenario 'GET /users/sign_in creates a new user account' do
    visit new_user_session_path
    fill_in 'user_name', with: 'Name Surname'
    fill_in 'user_username', with: 'Great'
    fill_in 'user_email', with: 'name@mail.com'
    fill_in 'user_password_sign_up', with: 'password1234'
    expect { click_button 'Sign up' }.to change { User.count }.by(1)
  end

  scenario 'Successful user signin invalidates password reset token' do
    user = create(:user)
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
end
