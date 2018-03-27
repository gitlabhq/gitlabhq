module NotificationsHelper
  include IconsHelper

  def notification_icon_class(level)
    case level.to_sym
    when :disabled
      'microphone-slash'
    when :participating
      'volume-up'
    when :watch
      'eye'
    when :mention
      'at'
    when :global
      'globe'
    end
  end

  def notification_icon(level, text = nil)
    icon("#{notification_icon_class(level)} fw", text: text)
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
    end
  end

  def notification_list_item(level, setting)
    title = notification_title(level)

    data = {
      notification_level: level,
      notification_title: title
    }

    content_tag(:li, role: "menuitem") do
      link_to '#', class: "update-notification #{('is-active' if setting.level == level)}", data: data do
        link_output = content_tag(:strong, title, class: 'dropdown-menu-inner-title')
        link_output << content_tag(:span, notification_description(level), class: 'dropdown-menu-inner-content')
      end
    end
  end

  # Identifier to trigger individually dropdowns and custom settings modals in the same view
  def notifications_menu_identifier(type, notification_setting)
    "#{type}-#{notification_setting.user_id}-#{notification_setting.source_id}-#{notification_setting.source_type}"
  end

  # Create hidden field to send notification setting source to controller
  def hidden_setting_source_input(notification_setting)
    return unless notification_setting.source_type

    hidden_field_tag "#{notification_setting.source_type.downcase}_id", notification_setting.source_id
  end

  def notification_event_name(event)
    # All values from NotificationSetting::EMAIL_EVENTS
    case event
    when :success_pipeline
      s_('NotificationEvent|Successful pipeline')
    else
      N_('NotificationEvent|New note')
      N_('NotificationEvent|New issue')
      N_('NotificationEvent|Reopen issue')
      N_('NotificationEvent|Close issue')
      N_('NotificationEvent|Reassign issue')
      N_('NotificationEvent|New merge request')
      N_('NotificationEvent|Close merge request')
      N_('NotificationEvent|Reassign merge request')
      N_('NotificationEvent|Merge merge request')
      N_('NotificationEvent|Failed pipeline')
      s_(event.to_s.humanize)
    end
  end
end
