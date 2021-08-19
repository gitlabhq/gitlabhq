# frozen_string_literal: true

if Gitlab.config.gitlab.cdn_host.present?
  Rails.application.configure do
    config.after_initialize do
      # Enable serving of images, stylesheets, and JavaScripts from an asset server
      Rails.application.config.action_controller.asset_host = Gitlab.config.gitlab.cdn_host

      # If ActionController::Base is called before this initializer, then we must set
      # the configuration directly.
      # See https://github.com/rails/rails/issues/16209
      ActionController::Base.asset_host = Gitlab.config.gitlab.cdn_host
    end
  end
end
