# frozen_string_literal: true

module CookiesHelper
  def set_secure_cookie(key, value, httponly: false, permanent: false)
    cookie_jar = permanent ? cookies.permanent : cookies

    cookie_jar[key] = { value: value, secure: Gitlab.config.gitlab.https, httponly: httponly }
  end
end
