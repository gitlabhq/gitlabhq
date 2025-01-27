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
      group_visibility_level_description(level, form_model)
    end
  end

  def visibility_icon_description(form_model)
    if form_model.respond_to?(:visibility_level_allowed_as_fork?)
      project_visibility_icon_description(form_model.visibility_level)
    elsif form_model.respond_to?(:visibility_level_allowed_by_sub_groups?)
      group_visibility_icon_description(form_model.visibility_level)
    end
  end

  def visibility_level_label(level)
    Project.visibility_levels.key(level)
  end

  def restricted_visibility_levels(show_all = false)
    return [] if current_user.can_admin_all_resources? && !show_all

    Gitlab::CurrentSettings.restricted_visibility_levels || []
  end

  delegate :default_project_visibility, :default_group_visibility,
    to: :'Gitlab::CurrentSettings.current_application_settings'

  def disallowed_visibility_level?(form_model, level)
    return false unless form_model.respond_to?(:visibility_level_allowed?)

    !form_model.visibility_level_allowed?(level)
  end

  def disallowed_visibility_level_by_organization?(form_model, level)
    return false unless form_model.respond_to?(:visibility_level_allowed_by_organization?)

    !form_model.visibility_level_allowed_by_organization?(level)
  end

  def disallowed_visibility_level_by_parent?(form_model, level)
    return false unless form_model.respond_to?(:visibility_level_allowed_by_parent?)

    !form_model.visibility_level_allowed_by_parent?(level)
  end

  def disallowed_visibility_level_by_projects?(form_model, level)
    return false unless form_model.respond_to?(:visibility_level_allowed_by_projects?)

    !form_model.visibility_level_allowed_by_projects?(level)
  end

  def disallowed_visibility_level_by_sub_groups?(form_model, level)
    return false unless form_model.respond_to?(:visibility_level_allowed_by_sub_groups?)

    !form_model.visibility_level_allowed_by_sub_groups?(level)
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

  def all_visibility_levels
    Gitlab::VisibilityLevel.values
  end

  def available_visibility_levels(form_model)
    Gitlab::VisibilityLevel.values.reject do |level|
      disallowed_visibility_level?(form_model, level) ||
        restricted_visibility_levels.include?(level)
    end
  end

  def disabled_visibility_level?(form_model, level)
    disallowed_visibility_level?(form_model, level) ||
      restricted_visibility_level?(level)
  end

  def restricted_visibility_level?(level)
    restricted_visibility_levels.include?(level)
  end

  def snippets_selected_visibility_level(visibility_levels, selected)
    visibility_levels.find { |level| level == selected } || visibility_levels.min
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

  def project_visibility_level_description(level)
    case level
    when Gitlab::VisibilityLevel::PRIVATE
      s_(
        "VisibilityLevel|Project access must be granted explicitly to each user. " \
           "If this project is part of a group, access is granted to members of the group."
      )
    when Gitlab::VisibilityLevel::INTERNAL
      s_("VisibilityLevel|The project can be accessed by any logged in user except external users.")
    when Gitlab::VisibilityLevel::PUBLIC
      s_("VisibilityLevel|The project can be accessed without any authentication.")
    end
  end

  def show_updated_public_description_for_setting(group)
    group &&
      !group.new_record? &&
      Gitlab::CurrentSettings.current_application_settings.try(:should_check_namespace_plan?)
  end

  def group_visibility_level_description(level, group = nil)
    case level
    when Gitlab::VisibilityLevel::PRIVATE
      s_("VisibilityLevel|The group and its projects can only be viewed by members.")
    when Gitlab::VisibilityLevel::INTERNAL
      s_(
        "VisibilityLevel|The group and any internal projects can be viewed by any logged in user except external users."
      )
    when Gitlab::VisibilityLevel::PUBLIC
      unless show_updated_public_description_for_setting(group)
        return s_('VisibilityLevel|The group and any public projects can be viewed without any authentication.')
      end

      Kernel.format(
        s_(
          'VisibilityLevel|The group, any public projects, and any of their members, issues, ' \
            'and merge requests can be viewed without authentication. ' \
          'Public groups and projects will be indexed by search engines. ' \
          'Read more about %{free_user_limit_doc_link_start}free user limits%{link_end}, ' \
          'or %{group_billings_link_start}upgrade to a paid tier%{link_end}.'
        ),
        free_user_limit_doc_link_start: "<a href='#{help_page_path('user/free_user_limit.md')}' target='_blank' " \
          "rel='noopener noreferrer'>".html_safe,
        group_billings_link_start: "<a href='#{group_billings_path(group)}' target='_blank' " \
          "rel='noopener noreferrer'>".html_safe,
        link_end: "</a>".html_safe
      ).html_safe
    end
  end

  def project_visibility_icon_description(level)
    "#{visibility_level_label(level)} - #{project_visibility_level_description(level)}"
  end

  def group_visibility_icon_description(level)
    "#{visibility_level_label(level)} - #{group_visibility_level_description(level)}"
  end
end
