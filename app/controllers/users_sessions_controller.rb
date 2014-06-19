class UsersSessionsController < Devise::SessionsController
  def create
    @return_to = params[:return_to]
    super
  end
end
