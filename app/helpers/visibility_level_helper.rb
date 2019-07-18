# frozen_string_literal: true

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
      _("The group and its projects can only be viewed by members.")
    when Gitlab::VisibilityLevel::INTERNAL
      _("The group and any internal projects can be viewed by any logged in user.")
    when Gitlab::VisibilityLevel::PUBLIC
      _("The group and any public projects can be viewed without any authentication.")
    end
  end

  def snippet_visibility_level_description(level, snippet = nil)
    case level
    when Gitlab::VisibilityLevel::PRIVATE
      if snippet.is_a? ProjectSnippet
        _("The snippet is visible only to project members.")
      else
        _("The snippet is visible only to me.")
      end
    when Gitlab::VisibilityLevel::INTERNAL
      _("The snippet is visible to any logged in user.")
    when Gitlab::VisibilityLevel::PUBLIC
      _("The snippet can be accessed without any authentication.")
    end
  end

  # Note: these messages closely mirror the form validation strings found in the project
  # model and any changes or additons to these may also need to be made there.
  def disallowed_project_visibility_level_description(level, project)
    level_name = Gitlab::VisibilityLevel.level_name(level).downcase
    reasons = []
    instructions = []

    unless project.visibility_level_allowed_as_fork?(level)
      reasons << "the fork source project has lower visibility"
    end

    unless project.visibility_level_allowed_by_group?(level)
      errors = visibility_level_errors_for_group(project.group, level_name)

      reasons << errors[:reason]
      instructions << errors[:instruction]
    end

    reasons = reasons.any? ? ' because ' + reasons.to_sentence : ''
    "This project cannot be #{level_name}#{reasons}.#{instructions.join}".html_safe
  end

  # Note: these messages closely mirror the form validation strings found in the group
  # model and any changes or additons to these may also need to be made there.
  def disallowed_group_visibility_level_description(level, group)
    level_name = Gitlab::VisibilityLevel.level_name(level).downcase
    reasons = []
    instructions = []

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
    "This group cannot be #{level_name}#{reasons}.#{instructions.join}".html_safe
  end

  def visibility_icon_description(form_model)
    if form_model.respond_to?(:visibility_level_allowed_as_fork?)
      project_visibility_icon_description(form_model.visibility_level)
    elsif form_model.respond_to?(:visibility_level_allowed_by_sub_groups?)
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

  # Visibility level can be restricted in two ways:
  #
  # 1. The group permissions (e.g. a subgroup is private, which requires
  # all projects to be private)
  # 2. The global allowed visibility settings, set by the admin
  def selected_visibility_level(form_model, requested_level)
    requested_level =
      if requested_level.present?
        requested_level.to_i
      else
        default_project_visibility
      end

    [requested_level, max_allowed_visibility_level(form_model)].min
  end

  def multiple_visibility_levels_restricted?
    restricted_visibility_levels.many? # rubocop: disable CodeReuse/ActiveRecord
  end

  def all_visibility_levels_restricted?
    Gitlab::VisibilityLevel.values == restricted_visibility_levels
  end

  private

  def max_allowed_visibility_level(form_model)
    # First obtain the maximum visibility for the project or group
    current_level = max_allowed_visibility_level_by_model(form_model)

    # Now limit this by the global setting
    Gitlab::VisibilityLevel.closest_allowed_level(current_level)
  end

  def max_allowed_visibility_level_by_model(form_model)
    current_level = Gitlab::VisibilityLevel::PRIVATE

    Gitlab::VisibilityLevel.values.sort.each do |value|
      if disallowed_visibility_level?(form_model, value)
        break
      else
        current_level = value
      end
    end

    current_level
  end

  def visibility_level_errors_for_group(group, level_name)
    group_name = link_to group.name, group_path(group)
    change_visiblity = link_to 'change the visibility', edit_group_path(group)

    { reason: "the visibility of #{group_name} is #{group.visibility}",
      instruction: " To make this group #{level_name}, you must first #{change_visiblity} of the parent group." }
  end
end
