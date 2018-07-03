class CookieRestriction
  def initialize(name)
    @name = name
  end

  def cookie_name
    "enable_#{@name}"
  end

  def cookie_feature
    :"skip_#{@name}_cookie_restriction"
  end

  def cookie_required?
    !Feature.enabled?(cookie_feature)
  end

  def active?(cookies)
    !cookie_required? || cookie_enabled?(cookies)
  end

  private

  def cookie_enabled?(cookies)
    ::Gitlab::Utils.to_boolean(cookies[cookie_name])
  end
end
