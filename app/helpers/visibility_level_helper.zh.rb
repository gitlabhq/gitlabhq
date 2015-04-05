module VisibilityLevelHelper
  def visibility_level_color(level)
    case level
    when Gitlab::VisibilityLevel::PRIVATE
      'vs-private'
    when Gitlab::VisibilityLevel::INTERNAL
      'vs-internal'
    when Gitlab::VisibilityLevel::PUBLIC
      'vs-public'
    end
  end

  def visibility_level_description(level)
    capture_haml do
      haml_tag :span do
        case level
        when Gitlab::VisibilityLevel::PRIVATE
          haml_concat "给每个用户的项目访问权限必须明确定义."
        when Gitlab::VisibilityLevel::INTERNAL
          haml_concat "项目可以被任何登录的用户克隆."
        when Gitlab::VisibilityLevel::PUBLIC
          haml_concat "项目可以在未认证的情况下被克隆."
        end
      end
    end
  end

  def snippet_visibility_level_description(level)
    capture_haml do
      haml_tag :span do
        case level
        when Gitlab::VisibilityLevel::PRIVATE
          haml_concat "代码片段仅自己可见"
        when Gitlab::VisibilityLevel::INTERNAL
          haml_concat "代码片段对登录用户可见."
        when Gitlab::VisibilityLevel::PUBLIC
          haml_concat "代码片段对任何人可见, 勿需认证登录."
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

  def restricted_visibility_levels(show_all = false)
    return [] if current_user.is_admin? && !show_all
    current_application_settings.restricted_visibility_levels || []
  end
end
