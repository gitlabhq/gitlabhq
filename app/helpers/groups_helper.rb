# frozen_string_literal: true

module GroupsHelper
  def group_overview_nav_link_paths
    %w[
      groups#activity
      groups#subgroups
      labels#index
      group_members#index
    ]
  end

  def group_settings_nav_link_paths
    %w[
      groups#projects
      groups#edit
      badges#index
      repository#show
      ci_cd#show
      integrations#index
      integrations#edit
      ldap_group_links#index
      hooks#index
      pipeline_quota#index
      applications#index
      applications#show
      applications#edit
      packages_and_registries#show
      groups/runners#show
      groups/runners#edit
    ]
  end

  def group_packages_nav_link_paths
    %w[
      groups/packages#index
      groups/container_registries#index
    ]
  end

  def group_information_title(group)
    group.subgroup? ? _('Subgroup information') : _('Group information')
  end

  def group_container_registry_nav?
    Gitlab.config.registry.enabled &&
      can?(current_user, :read_container_image, @group)
  end

  def group_sidebar_links
    @group_sidebar_links ||= get_group_sidebar_links
  end

  def group_sidebar_link?(link)
    group_sidebar_links.include?(link)
  end

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

  def group_issues_count(state:)
    IssuesFinder
      .new(current_user, group_id: @group.id, state: state, non_archived: true, include_subgroups: true)
      .execute
      .count
  end

  def group_merge_requests_count(state:)
    MergeRequestsFinder
      .new(current_user, group_id: @group.id, state: state, non_archived: true, include_subgroups: true)
      .execute
      .count
  end

  def cached_issuables_count(group, type: nil)
    count_service = issuables_count_service_class(type)
    return unless count_service.present?

    issuables_count = count_service.new(group, current_user).count
    format_issuables_count(count_service, issuables_count)
  end

  def group_dependency_proxy_url(group)
    # The namespace path can include uppercase letters, which
    # Docker doesn't allow. The proxy expects it to be downcased.
    "#{group_url(group).downcase}#{DependencyProxy::URL_SUFFIX}"
  end

  def group_icon_url(group, options = {})
    if group.is_a?(String)
      group = Group.find_by_full_path(group)
    end

    group.try(:avatar_url) || ActionController::Base.helpers.image_path('no_group_avatar.png')
  end

  def group_title(group, name = nil, url = nil)
    @has_group_title = true
    full_title = []

    sorted_ancestors(group).with_route.reverse_each.with_index do |parent, index|
      if index > 0
        add_to_breadcrumb_dropdown(group_title_link(parent, hidable: false, show_avatar: true, for_dropdown: true), location: :before)
      else
        full_title << breadcrumb_list_item(group_title_link(parent, hidable: false))
      end

      push_to_schema_breadcrumb(simple_sanitize(parent.name), group_path(parent))
    end

    full_title << render("layouts/nav/breadcrumbs/collapsed_dropdown", location: :before, title: _("Show parent subgroups"))

    full_title << breadcrumb_list_item(group_title_link(group))
    push_to_schema_breadcrumb(simple_sanitize(group.name), group_path(group))

    if name
      full_title << ' &middot; '.html_safe + link_to(simple_sanitize(name), url, class: 'group-path breadcrumb-item-text js-breadcrumb-item-text')
      push_to_schema_breadcrumb(simple_sanitize(name), url)
    end

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

  def remove_group_message(group)
    _("You are going to remove %{group_name}, this will also delete all of its subgroups and projects. Removed groups CANNOT be restored! Are you ABSOLUTELY sure?") %
      { group_name: group.name }
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
    s_("GroupSettings|This setting is only available on the top-level group and it applies to all subgroups. Groups that have already been shared with a group outside %{group} will still be shared, and this access will have to be revoked manually.").html_safe % { group: link_to_group(group) }
  end

  def parent_group_options(current_group)
    exclude_groups = current_group.self_and_descendants.pluck_primary_key
    exclude_groups << current_group.parent_id if current_group.parent_id
    groups = GroupsFinder.new(current_user, min_access_level: Gitlab::Access::OWNER, exclude_group_ids: exclude_groups).execute.sort_by(&:human_name).map do |group|
      { id: group.id, text: group.human_name }
    end

    groups.to_json
  end

  def group_packages_nav?
    group_packages_list_nav? ||
      group_container_registry_nav?
  end

  def group_dependency_proxy_nav?
    @group.dependency_proxy_feature_available?
  end

  def group_packages_list_nav?
    @group.packages_feature_enabled?
  end

  def show_invite_banner?(group)
    can?(current_user, :admin_group, group) &&
    !just_created? &&
    !multiple_members?(group)
  end

  def render_setting_to_allow_project_access_token_creation?(group)
    group.root? && current_user.can?(:admin_setting_to_allow_project_access_token_creation, group)
  end

  def show_thanks_for_purchase_banner?
    params.key?(:purchased_quantity) && params[:purchased_quantity].to_i > 0
  end

  def project_list_sort_by
    @group_projects_sort || @sort || params[:sort] || sort_value_recently_created
  end

  private

  def just_created?
    flash[:notice] =~ /successfully created/
  end

  def multiple_members?(group)
    group.member_count > 1 || group.members_with_parents.count > 1
  end

  def get_group_sidebar_links
    links = [:overview, :group_members]

    resources = [:activity, :issues, :boards, :labels, :milestones,
                 :merge_requests]
    links += resources.select do |resource|
      can?(current_user, "read_group_#{resource}".to_sym, @group)
    end

    if can?(current_user, :read_cluster, @group)
      links << :kubernetes
    end

    if can?(current_user, :admin_group, @group)
      links << :settings
    end

    if can?(current_user, :read_wiki, @group)
      links << :wiki
    end

    links
  end

  def group_title_link(group, hidable: false, show_avatar: false, for_dropdown: false)
    link_to(group_path(group), class: "group-path #{'breadcrumb-item-text' unless for_dropdown} js-breadcrumb-item-text #{'hidable' if hidable}") do
      icon = group_icon(group, class: "avatar-tile", width: 15, height: 15) if (group.try(:avatar_url) || show_avatar) && !Rails.env.test?
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
    s_("GroupSettings|This setting will be applied to all subgroups unless overridden by a group owner. Groups that already have access to the project will continue to have access unless removed manually.")
  end

  def ancestor_locked_but_you_can_override(group)
    s_("GroupSettings|This setting is applied on %{ancestor_group}. You can override the setting or %{remove_ancestor_share_with_group_lock}.").html_safe % { ancestor_group: ancestor_group(group), remove_ancestor_share_with_group_lock: remove_the_share_with_group_lock_from_ancestor(group) }
  end

  def ancestor_locked_so_ask_the_owner(group)
    s_("GroupSettings|This setting is applied on %{ancestor_group}. To share projects in this group with another group, ask the owner to override the setting or %{remove_ancestor_share_with_group_lock}.").html_safe % { ancestor_group: ancestor_group(group), remove_ancestor_share_with_group_lock: remove_the_share_with_group_lock_from_ancestor(group) }
  end

  def ancestor_locked_and_has_been_overridden(group)
    s_("GroupSettings|This setting is applied on %{ancestor_group} and has been overridden on this subgroup.").html_safe % { ancestor_group: ancestor_group(group) }
  end

  def issuables_count_service_class(type)
    if type == :issues
      Groups::OpenIssuesCountService
    elsif type == :merge_requests
      Groups::MergeRequestsCountService
    end
  end

  def format_issuables_count(count_service, count)
    if count > count_service::CACHED_COUNT_THRESHOLD
      ActiveSupport::NumberHelper
        .number_to_human(
          count,
          units: { thousand: 'k', million: 'm' }, precision: 1, significant: false, format: '%n%u'
        )
    else
      number_with_delimiter(count)
    end
  end
end

GroupsHelper.prepend_mod_with('GroupsHelper')
