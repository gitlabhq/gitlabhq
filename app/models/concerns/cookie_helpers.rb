module CookieHelpers
  def cookie_key
    "#{model_name.singular}_#{id}"
  end
end
