# frozen_string_literal: true

module ReminderEmailsHelper
  def invitation_reminder_salutation(reminder_index, format: nil)
    case reminder_index
    when 0
      s_('InviteReminderEmail|Invitation pending')
    when 1
      if format == :html
        s_('InviteReminderEmail|Hey there %{wave_emoji}').html_safe % { wave_emoji: Gitlab::Emoji.gl_emoji_tag('wave') }
      else
        s_('InviteReminderEmail|Hey there!')
      end
    when 2
      s_('InviteReminderEmail|In case you missed it...')
    end
  end

  def invitation_reminder_body(member, reminder_index, format: nil)
    options = {
      inviter: sanitize_name(member.created_by.name),
      strong_start: '',
      strong_end: '',
      project_or_group_name: member_source.human_name,
      project_or_group: member_source.model_name.singular,
      role: member.human_access.downcase
    }

    if format == :html
      options.merge!(
        inviter: (link_to member.created_by.name, user_url(member.created_by)).html_safe,
        strong_start: '<strong>'.html_safe,
        strong_end: '</strong>'.html_safe
      )
    end

    if reminder_index == 2
      options[:invitation_age] = (Date.current - member.created_at.to_date).to_i
    end

    body = invitation_reminder_body_text(reminder_index)

    (format == :html ? html_escape(body) : body ) % options
  end

  def invitation_reminder_accept_link(token, format: nil)
    case format
    when :html
      link_to s_('InviteReminderEmail|Accept invitation'), invite_url(token), class: 'invite-btn-join'
    else
      s_('InviteReminderEmail|Accept invitation: %{invite_url}') % { invite_url: invite_url(token) }
    end
  end

  def invitation_reminder_decline_link(token, format: nil)
    case format
    when :html
      link_to s_('InviteReminderEmail|Decline invitation'), decline_invite_url(token), class: 'invite-btn-decline'
    else
      s_('InviteReminderEmail|Decline invitation: %{decline_url}') % { decline_url: decline_invite_url(token) }
    end
  end

  private

  def invitation_reminder_body_text(reminder_index)
    case reminder_index
    when 0
      s_('InviteReminderEmail|%{inviter} is waiting for you to join the %{strong_start}%{project_or_group_name}%{strong_end} %{project_or_group} as a %{role}.')
    when 1
      s_('InviteReminderEmail|This is a friendly reminder that %{inviter} invited you to join the %{strong_start}%{project_or_group_name}%{strong_end} %{project_or_group} as a %{role}.')
    when 2
      s_("InviteReminderEmail|It's been %{invitation_age} days since %{inviter} invited you to join the %{strong_start}%{project_or_group_name}%{strong_end} %{project_or_group} as a %{role}. What would you like to do?")
    end
  end
end
