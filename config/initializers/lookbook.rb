# frozen_string_literal: true

if Rails.env.development?
  # :nocov: Lookbook is only available in development
  Lookbook::ApplicationController.class_eval do
    content_security_policy false
  end

  Rails.application.configure do
    config.lookbook.experimental_features = [:pages]
    config.lookbook.page_paths = ["#{config.root}/spec/components/docs"]
  end
  # :nocov:
end
