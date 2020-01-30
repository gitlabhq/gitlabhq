# frozen_string_literal: true

# This file requires config/initializers/1_settings.rb

if Rails.env.development?
  Rails.application.config.hosts << Gitlab.config.gitlab.host
end
