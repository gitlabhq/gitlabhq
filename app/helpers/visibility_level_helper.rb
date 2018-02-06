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
      _("Project access must be granted explicitly to each user.")
    when Gitlab::VisibilityLevel::INTERNAL
      _("The project can be accessed by any logged in user.")
    when Gitlab::VisibilityLevel::PUBLIC
      _("The project can be accessed without any authentication.")
    end
  end

  def group_visibility_level_description(level)
    case level
    when Gitlab::VisibilityLevel::PRIVATE
      "The group and its projects can only be viewed by members."
    when Gitlab::VisibilityLevel::INTERNAL
      "The group and any internal projects can be viewed by any logged in user."
    when Gitlab::VisibilityLevel::PUBLIC
      "The group and any public projects can be viewed without any authentication."
    end
  end

  def snippet_visibility_level_description(level, snippet = nil)
    case level
    when Gitlab::VisibilityLevel::PRIVATE
      if snippet.is_a? ProjectSnippet
        "The snippet is visible only to project members."
      else
        "The snippet is visible only to me."
      end
    when Gitlab::VisibilityLevel::INTERNAL
      "The snippet is visible to any logged in user."
    when Gitlab::VisibilityLevel::PUBLIC
      "The snippet can be accessed without any authentication."
    end
  end

  def restricted_visibility_level_description(level)
    level_name = Gitlab::VisibilityLevel.level_name(level)
    "#{level_name.capitalize} visibility has been restricted by the administrator."
  end

  def disallowed_visibility_level_description(level, form_model)
    case form_model
    when Project
      disallowed_project_visibility_level_description(level, form_model)
    when Group
      disallowed_group_visibility_level_description(level, form_model)
    end
  end

  # Note: these messages closely mirror the form validation strings found in the project
  # model and any changes or additons to these may also need to be made there.
  def disallowed_project_visibility_level_description(level, project)
    level_name = Gitlab::VisibilityLevel.level_name(level).downcase
    reasons = []
    instructions = ''

    unless project.visibility_level_allowed_as_fork?(level)
      reasons << "the fork source project has lower visibility"
    end

    unless project.visibility_level_allowed_by_group?(level)
      errors = visibility_level_errors_for_group(project.group, level_name)

      reasons << errors[:reason]
      instructions << errors[:instruction]
    end

    reasons = reasons.any? ? ' because ' + reasons.to_sentence : ''
    "This project cannot be #{level_name}#{reasons}.#{instructions}".html_safe
  end

  # Note: these messages closely mirror the form validation strings found in the group
  # model and any changes or additons to these may also need to be made there.
  def disallowed_group_visibility_level_description(level, group)
    level_name = Gitlab::VisibilityLevel.level_name(level).downcase
    reasons = []
    instructions = ''

    unless group.visibility_level_allowed_by_projects?(level)
      reasons << "it contains projects with higher visibility"
    end

    unless group.visibility_level_allowed_by_sub_groups?(level)
      reasons << "it contains sub-groups with higher visibility"
    end

    unless group.visibility_level_allowed_by_parent?(level)
      errors = visibility_level_errors_for_group(group.parent, level_name)

      reasons << errors[:reason]
      instructions << errors[:instruction]
    end

    reasons = reasons.any? ? ' because ' + reasons.to_sentence : ''
    "This group cannot be #{level_name}#{reasons}.#{instructions}".html_safe
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
    # The visibility level can be:
    # 'VisibilityLevel|Private', 'VisibilityLevel|Internal', 'VisibilityLevel|Public'
    s_(Project.visibility_levels.key(level))
  end

  def restricted_visibility_levels(show_all = false)
    return [] if current_user.admin? && !show_all

    Gitlab::CurrentSettings.restricted_visibility_levels || []
  end

  delegate  :default_project_visibility,
            :default_group_visibility,
            to: :'Gitlab::CurrentSettings.current_application_settings'

  def disallowed_visibility_level?(form_model, level)
    return false unless form_model.respond_to?(:visibility_level_allowed?)

    !form_model.visibility_level_allowed?(level)
  end

  private

  def visibility_level_errors_for_group(group, level_name)
    group_name = link_to group.name, group_path(group)
    change_visiblity = link_to 'change the visibility', edit_group_path(group)

    { reason: "the visibility of #{group_name} is #{group.visibility}",
      instruction: " To make this group #{level_name}, you must first #{change_visiblity} of the parent group." }
  end
end
