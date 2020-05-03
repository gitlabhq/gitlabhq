# frozen_string_literal: true

Rails.application.configure do
  # Prevents the default engine from being mounted because
  # we're running ActionCable as a standalone server
  config.action_cable.mount_path = nil
  config.action_cable.url = Gitlab::Utils.append_path(Gitlab.config.gitlab.relative_url_root, '/-/cable')
  config.action_cable.worker_pool_size = Gitlab.config.action_cable.worker_pool_size
end
