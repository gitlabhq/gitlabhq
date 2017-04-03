class UserUrlConstrainer
  def matches?(request)
    User.find_by_username(request.params[:username]).present?
  end
end
