# frozen_string_literal: true

module UpdateVisibilityLevel
  # check that user is allowed to set specified visibility_level
  def valid_visibility_level_change?(target, new_visibility)
    return true unless new_visibility

    new_visibility_level = Gitlab::VisibilityLevel.level_value(new_visibility, fallback_value: nil)

    if new_visibility_level != target.visibility_level_value
      unless can?(current_user, :change_visibility_level, target) &&
          Gitlab::VisibilityLevel.allowed_for?(current_user, new_visibility_level)

        deny_visibility_level(target, new_visibility_level)
        return false
      end
    end

    true
  end
end
