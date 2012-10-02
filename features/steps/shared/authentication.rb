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

  def current_user
    @user || User.first
  end
end
