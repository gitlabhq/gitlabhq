# frozen_string_literal: true

module InviteMembersHelper
  include Gitlab::Utils::StrongMemoize

  def can_invite_members_for_project?(project)
    Feature.enabled?(:invite_members_group_modal, project.group) && can_manage_project_members?(project)
  end

  def can_invite_group_for_project?(project)
    Feature.enabled?(:invite_members_group_modal, project.group) && project.allowed_to_share_with_group?
  end

  def directly_invite_members?
    strong_memoize(:directly_invite_members) do
      can_import_members?
    end
  end

  def invite_group_members?(group)
    experiment_enabled?(:invite_members_empty_group_version_a) && Ability.allowed?(current_user, :admin_group_member, group)
  end

  def dropdown_invite_members_link(form_model)
    link_to invite_members_url(form_model),
            data: {
              'track-event': 'click_link',
              'track-label': tracking_label,
              'track-property': experiment_tracking_category_and_group(:invite_members_new_dropdown)
            } do
      invite_member_link_content
    end
  end

  def invite_accepted_notice(member)
    case member.source
    when Project
      _("You have been granted %{member_human_access} access to project %{name}.") %
        { member_human_access: member.human_access, name: member.source.name }
    when Group
      _("You have been granted %{member_human_access} access to group %{name}.") %
        { member_human_access: member.human_access, name: member.source.name }
    end
  end

  private

  def invite_members_url(form_model)
    case form_model
    when Project
      project_project_members_path(form_model)
    when Group
      group_group_members_path(form_model)
    end
  end

  def invite_member_link_content
    text = s_('InviteMember|Invite members')

    return text unless experiment_enabled?(:invite_members_new_dropdown)

    "#{text} #{emoji_icon('shaking_hands', 'aria-hidden': true, class: 'gl-font-base gl-vertical-align-baseline')}".html_safe
  end
end
