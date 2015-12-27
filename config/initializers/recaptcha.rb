if Gitlab.config.recaptcha.enabled
  Recaptcha.configure do |config|
    config.public_key  = Gitlab.config.recaptcha['public_key']
    config.private_key = Gitlab.config.recaptcha['private_key']
  end
end
