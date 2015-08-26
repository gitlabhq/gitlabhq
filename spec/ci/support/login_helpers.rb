module LoginHelpers
  def login_as(role)
    raise 'Only :user allowed' unless role == :user
    stub_gitlab_calls
    login_with(:user)
  end

  # Internal: Login as the specified user
  #
  # user - User instance to login with
  def login_with(user)
    visit callback_user_sessions_path(code: "some_auth_code_here")
  end

  def logout
    click_link "Logout" rescue nil
  end

  def skip_admin_auth
    ApplicationController.any_instance.stub(authenticate_admin!: true)
  end
end
