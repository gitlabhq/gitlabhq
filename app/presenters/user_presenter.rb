# frozen_string_literal: true

class UserPresenter < Gitlab::View::Presenter::Delegated
  presents :user

  def web_url
    Gitlab::Routing.url_helpers.user_url(user)
  end
end
