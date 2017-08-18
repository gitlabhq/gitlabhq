module Avatarable
  extend ActiveSupport::Concern

  def avatar_path(only_path: true)
    return unless self[:avatar].present?

    # If only_path is true then use the relative path of avatar.
    # Otherwise use full path (including host).
    asset_host = ActionController::Base.asset_host
    gitlab_host = only_path ? gitlab_config.relative_url_root : gitlab_config.url

    # If asset_host is set then it is expected that assets are handled by a standalone host.
    # That means we do not want to get GitLab's relative_url_root option anymore.
    host = asset_host.present? ? asset_host : gitlab_host

    [host, avatar.url].join
  end
end
