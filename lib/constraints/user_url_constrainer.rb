class UserUrlConstrainer
  def matches?(request)
    full_path = request.params[:username]

    return false unless DynamicPathValidator.valid_user_path?(full_path)

    User.find_by_full_path(full_path, follow_redirects: request.get?).present?
  end
end
