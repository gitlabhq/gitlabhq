module VisibilityLevelHelper
  def visibility_level_color(level)
    case level
    when Gitlab::VisibilityLevel::PRIVATE
      'cgreen'
    when Gitlab::VisibilityLevel::INTERNAL
      'camber'
    when Gitlab::VisibilityLevel::PUBLIC
      'cblue'
    end
  end

  def visibility_level_description(level)
    capture_haml do
      haml_tag :span do
        case level
        when Gitlab::VisibilityLevel::PRIVATE
          haml_concat "Visible only to you and explicitly allowed users."
        when Gitlab::VisibilityLevel::INTERNAL
          haml_concat "Visible to any logged in user."
        when Gitlab::VisibilityLevel::PUBLIC
          haml_concat "Visible without any authentication."
        end
      end
    end
  end

  def visibility_level_icon(level)
    case level
    when Gitlab::VisibilityLevel::PRIVATE
      private_icon
    when Gitlab::VisibilityLevel::INTERNAL
      internal_icon
    when Gitlab::VisibilityLevel::PUBLIC
      public_icon
    end
  end

  def visibility_level_label(level)
    Gitlab::VisibilityLevel::options.key(level)
  end

  def restricted_visibility_levels
    current_user.is_admin? ? [] : gitlab_config.restricted_visibility_levels
  end
end
