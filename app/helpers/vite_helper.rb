# frozen_string_literal: true

module ViteHelper
  def universal_javascript_include_tag(*args)
    if vite_enabled
      vite_javascript_tag(*args)
    else
      javascript_include_tag(*args)
    end
  end

  def universal_asset_path(*args)
    if vite_enabled
      vite_asset_path(*args)
    else
      asset_path(*args)
    end
  end

  private

  def vite_enabled
    Feature.enabled?(:vite) && !Rails.env.test? && vite_running
  end

  def vite_running
    ViteRuby.instance.dev_server_running?
  end
end
