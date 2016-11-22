module EE
  # User EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be **prepended** in the `User` model
  module User
    def avatar_url(size = nil, scale = 2)
      if self[:avatar].present? && ::Gitlab::Geo.secondary?
        File.join(::Gitlab::Geo.primary_node.url, avatar.url)
      else
        super
      end
    end
  end
end
