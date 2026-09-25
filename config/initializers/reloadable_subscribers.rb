# frozen_string_literal: true

if Rails.application.config.reloading_enabled?
  detached_subscribers = []

  Rails.application.reloader.before_class_unload do
    detached_subscribers = Gitlab::ReloadableSubscribers.detach
  end

  Rails.application.reloader.to_prepare do
    Gitlab::ReloadableSubscribers.reattach(detached_subscribers)
    detached_subscribers = []
  end
end
