require Rails.root.join('spec', 'support', 'login_helpers')

module SharedAuthentication
  include Spinach::DSL
  include LoginHelpers

  Given 'I sign in as a user' do
    login_as :user
  end

  Given 'I sign in as an admin' do
    login_as :admin
  end

  step 'I sign in as "John Doe"' do
    login_with(user_exists("John Doe"))
  end

  step 'I sign in as "Mary Jane"' do
    login_with(user_exists("Mary Jane"))
  end

  step 'I should be redirected to sign in page' do
    current_path.should == new_user_session_path
  end

  def current_user
    @user || User.first
  end
end
