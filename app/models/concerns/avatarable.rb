module Avatarable
  extend ActiveSupport::Concern

  included do
    prepend ShadowMethods

    validate :avatar_type, if: ->(user) { user.avatar.present? && user.avatar_changed? }
    validates :avatar, file_size: { maximum: 200.kilobytes.to_i }

    mount_uploader :avatar, AvatarUploader
  end

  module ShadowMethods
    def avatar_url(**args)
      # We use avatar_path instead of overriding avatar_url because of carrierwave.
      # See https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/11001/diffs#note_28659864

      avatar_path(only_path: args.fetch(:only_path, true)) || super
    end
  end

  def avatar_type
    unless self.avatar.image?
      self.errors.add :avatar, "only images allowed"
    end
  end

  def avatar_path(only_path: true)
    return unless self[:avatar].present?

    asset_host = ActionController::Base.asset_host
    use_asset_host = asset_host.present?

    # Avatars for private and internal groups and projects require authentication to be viewed,
    # which means they can only be served by Rails, on the regular GitLab host.
    # If an asset host is configured, we need to return the fully qualified URL
    # instead of only the avatar path, so that Rails doesn't prefix it with the asset host.
    if use_asset_host && respond_to?(:public?) && !public?
      use_asset_host = false
      only_path = false
    end

    url_base = ""
    if use_asset_host
      url_base << asset_host unless only_path
    else
      url_base << gitlab_config.base_url unless only_path
      url_base << gitlab_config.relative_url_root
    end

    url_base + avatar.url
  end
end
