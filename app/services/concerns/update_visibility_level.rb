module UpdateVisibilityLevel
  def valid_visibility_level_change?(target, new_visibility)
    # check that user is allowed to set specified visibility_level
    if new_visibility && new_visibility.to_i != target.visibility_level
      unless can?(current_user, :change_visibility_level, target) &&
          Gitlab::VisibilityLevel.allowed_for?(current_user, new_visibility)

        deny_visibility_level(target, new_visibility)
        return false
      end
    end

    true
  end
end
