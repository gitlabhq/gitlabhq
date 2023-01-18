# frozen_string_literal: true

module BulkImports
  module VisibilityLevel
    private

    def visibility_level(entity, namespace, visibility_string)
      requested = requested_visibility_level(entity, visibility_string)
      max_allowed = max_allowed_visibility_level(namespace)

      return requested if max_allowed >= requested

      max_allowed
    end

    def requested_visibility_level(entity, visibility_string)
      Gitlab::VisibilityLevel.string_options[visibility_string] || entity.default_visibility_level
    end

    def max_allowed_visibility_level(namespace)
      return Gitlab::VisibilityLevel.allowed_levels.max if namespace.blank?

      Gitlab::VisibilityLevel.closest_allowed_level(namespace.visibility_level)
    end
  end
end
