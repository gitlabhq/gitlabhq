# frozen_string_literal: true

module CookiesHelper
  COOKIE_TYPE_PERMANENT = :permanent
  COOKIE_TYPE_ENCRYPTED = :encrypted

  def set_secure_cookie(key, value, httponly: false, expires: nil, type: nil)
    cookie_jar = case type
                 when COOKIE_TYPE_PERMANENT
                   cookies.permanent
                 when COOKIE_TYPE_ENCRYPTED
                   cookies.encrypted
                 else
                   cookies
                 end

    cookie_jar[key] = { value: value, secure: Gitlab.config.gitlab.https, httponly: httponly, expires: expires }
  end
end
