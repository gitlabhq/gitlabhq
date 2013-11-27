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
          haml_concat "Project access must be granted explicitly for each user."
        when Gitlab::VisibilityLevel::INTERNAL
          haml_concat "The project can be cloned by"
          haml_tag :em, "any logged in user."
          haml_concat "It will also be listed on the #{link_to "public access directory", public_root_path} for logged in users."
          haml_tag :em, "Any logged in user"
          haml_concat "will have #{link_to "Guest", help_permissions_path} permissions on the repository."
        when Gitlab::VisibilityLevel::PUBLIC
          haml_concat "The project can be cloned"
          haml_tag :em, "without any"
          haml_concat "authentication."
          haml_concat "It will also be listed on the #{link_to "public access directory", public_root_path}."
          haml_tag :em, "Any logged in user"
          haml_concat "will have #{link_to "Guest", help_permissions_path} permissions on the repository."
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
    Project.visibility_levels.key(level)
  end
  
  def restricted_visibility_levels
    current_user.is_admin? ? [] : gitlab_config.restricted_visibility_levels
  end
end