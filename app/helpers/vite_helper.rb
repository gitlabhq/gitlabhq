# frozen_string_literal: true

module ViteHelper
  private

  def vite_enabled
    Feature.enabled?(:vite) && !Rails.env.test? && vite_running
  end

  def vite_running
    ViteRuby.instance.dev_server_running?
  end
end
