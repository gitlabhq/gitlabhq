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
