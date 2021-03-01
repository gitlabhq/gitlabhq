# frozen_string_literal: true

module NotificationsHelper
  include IconsHelper

  def notification_icon_class(level)
    case level.to_sym
    when :disabled, :owner_disabled
      'notifications-off'
    when :participating
      'notifications'
    when :watch
      'eye'
    when :mention
      'at'
    when :global
      'earth'
    end
  end

  def notification_icon_level(notification_setting, emails_disabled = false)
    if emails_disabled
      'owner_disabled'
    elsif notification_setting.global?
      current_user.global_notification_setting.level
    else
      notification_setting.level
    end
  end

  def notification_icon(level)
    icon = notification_icon_class(level)
    return '' unless icon

    sprite_icon(icon)
  end

  def notification_title(level)
    # Can be anything in `NotificationSetting.level:
    case level.to_sym
    when :participating
      s_('NotificationLevel|Participate')
    when :mention
      s_('NotificationLevel|On mention')
    else
      N_('NotificationLevel|Global')
      N_('NotificationLevel|Watch')
      N_('NotificationLevel|Disabled')
      N_('NotificationLevel|Custom')
      level = "NotificationLevel|#{level.to_s.humanize}"
      s_(level)
    end
  end

  def notification_description(level)
    case level.to_sym
    when :participating
      _('You will only receive notifications for threads you have participated in')
    when :mention
      _('You will receive notifications only for comments in which you were @mentioned')
    when :watch
      _('You will receive notifications for any activity')
    when :disabled
      _('You will not get any notifications via email')
    when :global
      _('Use your global notification setting')
    when :custom
      _('You will only receive notifications for the events you choose')
    when :owner_disabled
      # Any change must be reflected in board_sidebar_subscription.vue
      _('Notifications have been disabled by the project or group owner')
    end
  end

  def show_unsubscribe_title?(noteable)
    can?(current_user, "read_#{noteable.to_ability_name}".to_sym, noteable)
  end

  def can_read_project?(project)
    can?(current_user, :read_project, project)
  end

  def notification_dropdown_items(notification_setting)
    NotificationSetting.levels.each_key.map do |level|
      next if level == "custom"
      next if level == "global" && notification_setting.source.nil?

      level
    end.compact
  end
end
