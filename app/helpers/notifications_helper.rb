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

    content_tag(:li, class: ('active' if setting.level == level)) do
      link_to '#', class: 'update-notification', data: data do
        notification_icon(level, title)
      end
    end
  end
end
