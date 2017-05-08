class UserUrlConstrainer
  def matches?(request)
    User.find_by_full_path(request.params[:username], follow_redirects: request.get?).present?
  end
end
