# frozen_string_literal: true

module GroupsHelper
  def can_change_group_visibility_level?(group)
    can?(current_user, :change_visibility_level, group)
  end

  def can_update_default_branch_protection?(group)
    can?(current_user, :update_default_branch_protection, group)
  end

  def can_change_share_with_group_lock?(group)
    can?(current_user, :change_share_with_group_lock, group)
  end

  def can_change_prevent_sharing_groups_outside_hierarchy?(group)
    can?(current_user, :change_prevent_sharing_groups_outside_hierarchy, group)
  end

  def can_disable_group_emails?(group)
    can?(current_user, :set_emails_disabled, group) && !group.parent&.emails_disabled?
  end

  def can_set_group_diff_preview_in_email?(group)
    return false if group.parent&.show_diff_preview_in_email?.equal?(false)

    can?(current_user, :set_show_diff_preview_in_email, group)
  end

  def can_admin_group_member?(group)
    Ability.allowed?(current_user, :admin_group_member, group)
  end

  def show_prevent_inviting_groups_outside_hierarchy_setting?(group)
    group.root?
  end

  def group_icon_url(group, options = {})
    group = Group.find_by_full_path(group) if group.is_a?(String)

    group.try(:avatar_url) || ActionController::Base.helpers.image_path('no_group_avatar.png')
  end

  def group_title(group)
    @has_group_title = true
    full_title = []

    sorted_ancestors(group).with_route.reverse_each.with_index do |parent, index|
      if index > 0
        add_to_breadcrumb_collapsed_links(
          { text: simple_sanitize(parent.name), href: group_path(parent), avatar_url: parent.try(:avatar_url) },
          location: :before
        )
      else
        full_title << breadcrumb_list_item(group_title_link(parent, hidable: false))
      end

      push_to_schema_breadcrumb(simple_sanitize(parent.name), group_path(parent), parent.try(:avatar_url))
    end

    full_title << render("layouts/nav/breadcrumbs/collapsed_inline_list", location: :before, title: _("Show all breadcrumbs"))

    full_title << breadcrumb_list_item(group_title_link(group))
    push_to_schema_breadcrumb(simple_sanitize(group.name), group_path(group), group.try(:avatar_url))

    full_title.join.html_safe
  end

  def projects_lfs_status(group)
    lfs_status =
      if group.lfs_enabled?
        group.projects.count(&:lfs_enabled?)
      else
        group.projects.count { |project| !project.lfs_enabled? }
      end

    size = group.projects.size

    if lfs_status == size
      'for all projects'
    else
      "for #{lfs_status} out of #{pluralize(size, 'project')}"
    end
  end

  def group_lfs_status(group)
    status = group.lfs_enabled? ? 'enabled' : 'disabled'

    content_tag(:span, class: "lfs-#{status}") do
      "#{status.humanize} #{projects_lfs_status(group)}"
    end
  end

  def group_confirm_modal_data(group:, remove_form_id: nil, permanently_remove: false, button_text: nil, has_security_policy_project: false)
    {
      remove_form_id: remove_form_id,
      button_text: button_text.nil? ? _('Delete group') : button_text,
      button_testid: 'remove-group-button',
      disabled: (group.linked_to_subscription? || has_security_policy_project).to_s,
      confirm_danger_message: remove_group_message(group, permanently_remove),
      phrase: group.full_path,
      html_confirmation_message: 'true'
    }
  end

  # Overridden in EE
  def remove_group_message(group, permanently_remove)
    content_tag :div do
      content = ''.html_safe
      content << content_tag(:span, _("You are about to delete the group %{group_name}.") % { group_name: group.name })

      additional_content = additional_removed_items(group)
      content << additional_content if additional_content.present?

      content << remove_group_warning
    end
  end

  def additional_removed_items(group)
    relations = {
      _('subgroup') => group.children,
      _('active project') => group.all_projects.non_archived,
      _('archived project') => group.all_projects.archived
    }

    counts = relations.filter_map do |singular, relation|
      count = limited_counter_with_delimiter(relation, limit: 100, include_zero: false)
      content_tag(:li, pluralize(count, singular)) if count
    end.join.html_safe

    if counts.present?
      content_tag(:span, _(" This action will also delete:")) +
        content_tag(:ul, counts)
    else
      ''.html_safe
    end
  end

  def remove_group_warning
    message = _('After you delete a group, you %{strongOpen}cannot%{strongClose} restore it or its components.')
    content_tag(:p, class: 'gl-mb-0') do
      ERB::Util.html_escape(message) % {
        strongOpen: '<strong>'.html_safe,
        strongClose: '</strong>'.html_safe
      }
    end
  end

  def share_with_group_lock_help_text(group)
    return default_help unless group.parent&.share_with_group_lock?

    if group.share_with_group_lock?
      if can?(current_user, :change_share_with_group_lock, group.parent)
        ancestor_locked_but_you_can_override(group)
      else
        ancestor_locked_so_ask_the_owner(group)
      end
    else
      ancestor_locked_and_has_been_overridden(group)
    end
  end

  def link_to_group(group)
    link_to(group.name, group_path(group))
  end

  def prevent_sharing_groups_outside_hierarchy_help_text(group)
    safe_format(s_("GroupSettings|Available only on the top-level group. Applies to all subgroups. Groups already shared with a group outside %{group} are still shared unless removed manually."), group: link_to_group(group))
  end

  def render_setting_to_allow_project_access_token_creation?(group)
    group.root? && current_user.can?(:admin_setting_to_allow_resource_access_token_creation, group)
  end

  def show_thanks_for_purchase_alert?(quantity)
    quantity.to_i > 0
  end

  def project_list_sort_by
    @group_projects_sort || @sort || params[:sort] || sort_value_recently_created
  end

  def subgroup_creation_data(group)
    {
      parent_group_url: group.parent && group_url(group.parent),
      parent_group_name: group.parent&.name,
      import_existing_group_path: new_group_path(parent_id: group.parent_id, anchor: 'import-group-pane'),
      is_saas: Gitlab.com?.to_s
    }
  end

  def group_name_and_path_app_data
    {
      base_path: root_url,
      mattermost_enabled: Gitlab.config.mattermost.enabled.to_s
    }
  end

  def group_overview_tabs_app_data(group)
    {
      group_id: group.id,
      subgroups_and_projects_endpoint: group_children_path(group, format: :json),
      shared_projects_endpoint: group_shared_projects_path(group, format: :json),
      inactive_projects_endpoint: group_children_path(group, format: :json, archived: 'only'),
      current_group_visibility: group.visibility,
      initial_sort: project_list_sort_by,
      show_schema_markup: 'true',
      new_subgroup_path: new_group_path(parent_id: group.id, anchor: 'create-group-pane'),
      new_project_path: new_project_path(namespace_id: group.id),
      empty_projects_illustration: image_path('illustrations/empty-state/empty-projects-md.svg'),
      empty_subgroup_illustration: image_path('illustrations/empty-state/empty-projects-md.svg'),
      render_empty_state: 'true',
      can_create_subgroups: can?(current_user, :create_subgroup, group).to_s,
      can_create_projects: can?(current_user, :create_projects, group).to_s
    }
  end

  def group_readme_app_data(group_readme)
    {
      web_path: group_readme.present.web_path,
      name: group_readme.present.name
    }
  end

  def show_group_readme?(group)
    return false unless group.group_readme

    can?(current_user, :read_code, group.readme_project)
  end

  def group_settings_readme_app_data(group)
    {
      group_readme_path: group.group_readme&.present&.web_path,
      readme_project_path: group.readme_project&.present&.path_with_namespace,
      group_path: group.full_path,
      group_id: group.id
    }
  end

  def enabled_git_access_protocol_options_for_group
    case ::Gitlab::CurrentSettings.enabled_git_access_protocol
    when nil, ""
      [[_("Both SSH and HTTP(S)"), "all"], [_("Only SSH"), "ssh"], [_("Only HTTP(S)"), "http"]]
    when "ssh"
      [[_("Only SSH"), "ssh"]]
    when "http"
      [[_("Only HTTP(S)"), "http"]]
    end
  end

  def new_custom_emoji_path(group)
    return unless group
    return unless can?(current_user, :create_custom_emoji, group)

    new_group_custom_emoji_path(group)
  end

  def access_level_roles_user_can_assign(group, roles)
    max_access_level = group.max_member_access_for_user(current_user)
    roles.select do |_name, access_level|
      access_level <= max_access_level
    end
  end

  def groups_projects_more_actions_dropdown_data(source)
    model_name = source.model_name.to_s.downcase
    dropdown_data = {
      is_group: source.is_a?(Group).to_s,
      id: source.id
    }

    return dropdown_data unless current_user

    if source.is_a?(Group)
      dropdown_data[:can_edit] = can?(current_user, :admin_group, source).to_s
      dropdown_data[:edit_path] = edit_group_path(source)
    else
      dropdown_data[:can_edit] = can?(current_user, :admin_project, source).to_s
      dropdown_data[:edit_path] = edit_project_path(source)
    end

    if can?(current_user, :"destroy_#{model_name}_member", source.members.find_by(user_id: current_user.id)) # rubocop: disable CodeReuse/ActiveRecord -- we need to fetch it
      dropdown_data[:leave_path] = polymorphic_path([:leave, source, :members])
      dropdown_data[:leave_confirm_message] = leave_confirmation_message(source)
    elsif source.requesters.find_by(user_id: current_user.id) # rubocop: disable CodeReuse/ActiveRecord -- we need to fetch it
      requester = source.requesters.find_by(user_id: current_user.id) # rubocop: disable CodeReuse/ActiveRecord -- we need to fetch it
      if can?(current_user, :withdraw_member_access_request, requester)
        dropdown_data[:withdraw_path] = polymorphic_path([:leave, source, :members])
        dropdown_data[:withdraw_confirm_message] = remove_member_message(requester)
      end
    elsif source.request_access_enabled && can?(current_user, :request_access, source)
      dropdown_data[:request_access_path] = polymorphic_path([:request_access, source, :members])
    end

    dropdown_data
  end

  def groups_list_with_filtered_search_app_data(endpoint)
    {
      endpoint: endpoint,
      initial_sort: project_list_sort_by
    }.to_json
  end

  def group_merge_requests(group)
    MergeRequestsFinder.new(current_user, group_id: group.id, include_subgroups: true, non_archived: true).execute
  end

  private

  def group_title_link(group, hidable: false, show_avatar: false)
    link_to(group_path(group), class: "group-path js-breadcrumb-item-text #{'hidable' if hidable}") do
      if group.try(:avatar_url) || show_avatar
        icon = render Pajamas::AvatarComponent.new(group, alt: group.name, class: "avatar-tile", size: 16)
      end

      [icon, simple_sanitize(group.name)].join.html_safe
    end
  end

  def ancestor_group(group)
    ancestor = oldest_consecutively_locked_ancestor(group)
    if can?(current_user, :read_group, ancestor)
      link_to ancestor.name, group_path(ancestor)
    else
      ancestor.name
    end
  end

  def remove_the_share_with_group_lock_from_ancestor(group)
    ancestor = oldest_consecutively_locked_ancestor(group)
    text = s_("GroupSettings|remove the share with group lock from %{ancestor_group_name}") % { ancestor_group_name: ancestor.name }
    if can?(current_user, :admin_group, ancestor)
      link_to text, edit_group_path(ancestor)
    else
      text
    end
  end

  def oldest_consecutively_locked_ancestor(group)
    sorted_ancestors(group).find do |group|
      !group.has_parent? || !group.parent.share_with_group_lock?
    end
  end

  # Ancestors sorted by hierarchy depth in bottom-top order.
  def sorted_ancestors(group)
    if group.root_ancestor.use_traversal_ids?
      group.ancestors(hierarchy_order: :asc)
    else
      group.ancestors
    end
  end

  def default_help
    s_("GroupSettings|Applied to all subgroups unless overridden by a group owner. Groups already added to the project lose access.")
  end

  def ancestor_locked_but_you_can_override(group)
    safe_format(s_("GroupSettings|This setting is applied on %{ancestor_group}. You can override the setting or %{remove_ancestor_share_with_group_lock}."), ancestor_group: ancestor_group(group), remove_ancestor_share_with_group_lock: remove_the_share_with_group_lock_from_ancestor(group))
  end

  def ancestor_locked_so_ask_the_owner(group)
    safe_format(s_("GroupSettings|This setting is applied on %{ancestor_group}. To share projects in this group with another group, ask the owner to override the setting or %{remove_ancestor_share_with_group_lock}."), ancestor_group: ancestor_group(group), remove_ancestor_share_with_group_lock: remove_the_share_with_group_lock_from_ancestor(group))
  end

  def ancestor_locked_and_has_been_overridden(group)
    safe_format(s_("GroupSettings|This setting is applied on %{ancestor_group} and has been overridden on this subgroup."), ancestor_group: ancestor_group(group))
  end

  def group_url_error_message
    s_('GroupSettings|Choose a group path that does not start with a dash or end with a period. It can also contain alphanumeric characters and underscores.')
  end

  # Maps `jobs_to_be_done` values to option texts
  def localized_jobs_to_be_done_choices
    {
      basics: _('I want to learn the basics of Git'),
      move_repository: _('I want to move my repository to GitLab from somewhere else'),
      code_storage: _('I want to store my code'),
      exploring: _('I want to explore GitLab to see if it’s worth switching to'),
      ci: _('I want to use GitLab CI with my existing repository'),
      other: _('A different reason')
    }.with_indifferent_access.freeze
  end
end

GroupsHelper.prepend_mod_with('GroupsHelper')
