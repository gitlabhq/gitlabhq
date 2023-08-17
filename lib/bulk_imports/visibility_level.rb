# frozen_string_literal: true

module BulkImports
  module VisibilityLevel
    private

    # Calculates visbility level based on the source and the destination namespace visbility levels
    # If there are visibility_level restrictions on the destination instance,
    # the highest allowed level less than the calculated level is returned
    def visibility_level(entity, namespace, visibility_string)
      requested = requested_visibility_level(entity, visibility_string)
      namespace_level = namespace&.visibility_level

      lowest_level = [requested, namespace_level].compact.min

      closet_allowed_level(lowest_level)
    end

    def requested_visibility_level(entity, visibility_string)
      Gitlab::VisibilityLevel.string_options[visibility_string] || entity.default_visibility_level
    end

    def closet_allowed_level(level)
      Gitlab::VisibilityLevel.closest_allowed_level(level)
    end
  end
end
