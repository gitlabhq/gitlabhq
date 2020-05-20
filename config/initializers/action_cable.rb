# frozen_string_literal: true

Rails.application.configure do
  # We only mount the ActionCable engine in tests where we run it in-app
  # For other environments, we run it on a standalone Puma server
  config.action_cable.mount_path = Rails.env.test? ? '/-/cable' : nil
  config.action_cable.url = Gitlab::Utils.append_path(Gitlab.config.gitlab.relative_url_root, '/-/cable')
  config.action_cable.worker_pool_size = Gitlab.config.action_cable.worker_pool_size
end
