module ApplicationSettingsHelper
  def gravatar_enabled?
    current_application_settings.gravatar_enabled?
  end

  def twitter_sharing_enabled?
    current_application_settings.twitter_sharing_enabled?
  end

  def signup_enabled?
    current_application_settings.signup_enabled?
  end

  def signin_enabled?
    current_application_settings.signin_enabled?
  end

  def extra_sign_in_text
    current_application_settings.sign_in_text
  end
end
