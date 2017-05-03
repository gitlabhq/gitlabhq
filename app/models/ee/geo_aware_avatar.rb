module EE
  # Avatars in Geo mixin
  #
  # This module is intended to encapsulate Geo-specific logic
  # and be **prepended** in the `Group`, `User`, `Project` models
  module GeoAwareAvatar
    def avatar_url(size = nil, scale = 2)
      if ::Gitlab::Geo.secondary? && self[:avatar].present?
        File.join(::Gitlab::Geo.primary_node.url, avatar.url)
      else
        super
      end
    end
  end
end
