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

  def notification_icon(level)
    icon("#{notification_icon_class(level)} fw")
  end

  def notification_title(level)
    case level.to_sym
    when :participating
      'Participate'
    when :mention
      'On mention'
    else
      level.to_s.titlecase
    end
  end

  def notification_list_item(level, setting)
    title = notification_title(level)

    data = {
      notification_level: level,
      notification_title: title
    }

    content_tag(:li, class: active_level_for(setting, level)) do
      link_to '#', class: 'update-notification', data: data do
        icon("#{notification_icon_class(level)} fw", text: title)
      end
    end
  end

  def active_level_for(setting, level)
    'active' if setting.level == level
  end
end
