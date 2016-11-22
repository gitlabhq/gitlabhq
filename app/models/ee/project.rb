module EE
  # Project EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be **prepended** in the `Project` model
  module Project
    # Display correct avatar in a secondary Geo node
    def avatar_url
      if self[:avatar].present? && ::Gitlab::Geo.secondary?
        File.join(::Gitlab::Geo.primary_node.url, avatar.url)
      else
        super
      end
    end
  end
end
