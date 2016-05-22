#encoding: utf-8
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

  # Return the description for the +level+ argument.
  #
  # +level+       One of the Gitlab::VisibilityLevel constants
  # +form_model+  Either a model object (Project, Snippet, etc.) or the name of
  #               a Project or Snippet class.
  def visibility_level_description(level, form_model)
    case form_model
    when Project
      project_visibility_level_description(level)
    when Group
      group_visibility_level_description(level)
    when Snippet
      snippet_visibility_level_description(level, form_model)
    end
  end

  def project_visibility_level_description(level)
    case level
    when Gitlab::VisibilityLevel::PRIVATE
      "项目必须明确授权给每个用户访问。"
    when Gitlab::VisibilityLevel::INTERNAL
      "项目可以被所有已登录用户克隆。"
    when Gitlab::VisibilityLevel::PUBLIC
      "项目可以被任何用户克隆。"
    end
  end

  def group_visibility_level_description(level)
    case level
    when Gitlab::VisibilityLevel::PRIVATE
      "该群组和其项目只有其成员能以看到。"
    when Gitlab::VisibilityLevel::INTERNAL
      "该群组和其内部项目只有已登录用户能看到。"
    when Gitlab::VisibilityLevel::PUBLIC
      "该群组和其公开项目可以被任何授权的用户看到。"
    end
  end

  def snippet_visibility_level_description(level, snippet = nil)
    case level
    when Gitlab::VisibilityLevel::PRIVATE
      if snippet.is_a? ProjectSnippet
        "该代码片段只有项目成员能看到。"
      else
        "该代码片段只有自己能看到。"
      end
    when Gitlab::VisibilityLevel::INTERNAL
      "该代码片段任何已登录用户都可以看到。"
    when Gitlab::VisibilityLevel::PUBLIC
      "该代码片段可以被任何授权的用户访问。"
    end
  end

  def visibility_icon_description(form_model)
    case form_model
    when Project
      project_visibility_icon_description(form_model.visibility_level)
    when Group
      group_visibility_icon_description(form_model.visibility_level)
    end
  end

  def group_visibility_icon_description(level)
    "#{visibility_level_label(level)} - #{group_visibility_level_description(level)}"
  end

  def project_visibility_icon_description(level)
    "#{visibility_level_label(level)} - #{project_visibility_level_description(level)}"
  end

  def visibility_level_label(level)
    Project.visibility_levels.key(level)
  end

  def restricted_visibility_levels(show_all = false)
    return [] if current_user.is_admin? && !show_all
    current_application_settings.restricted_visibility_levels || []
  end

  def default_project_visibility
    current_application_settings.default_project_visibility
  end

  def default_snippet_visibility
    current_application_settings.default_snippet_visibility
  end

  def default_group_visibility
    current_application_settings.default_group_visibility
  end

  def skip_level?(form_model, level)
    form_model.is_a?(Project) && !form_model.visibility_level_allowed?(level)
  end
end
