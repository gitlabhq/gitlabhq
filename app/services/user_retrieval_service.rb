class UserRetrievalService
  attr_accessor :login, :password

  def initialize(login, password)
    @login = login
    @password = password
  end

  def execute
    user = Gitlab::Auth.find_with_user_password(login, password)
    user unless user.two_factor_enabled?
  end
end