# frozen_string_literal: true

Rails.application.configure do |config|
  config.middleware.use(Gitlab::Middleware::Organizations::Current)
end
