# frozen_string_literal: true

Rails.application.configure do |config|
  config.middleware.use(Ci::JobToken::Middleware)
end
