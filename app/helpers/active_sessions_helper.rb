# frozen_string_literal: true

module ActiveSessionsHelper
  # Maps a device type as defined in `ActiveSession` to an svg icon name and
  # outputs the icon html.
  #
  # see `DeviceDetector::Device::DEVICE_NAMES` about the available device types
  def active_session_device_type_icon(active_session)
    icon_name =
      case active_session.device_type
      when 'smartphone', 'feature phone', 'phablet'
        'mobile'
      when 'tablet'
        'tablet'
      when 'tv', 'smart display', 'camera', 'portable media player', 'console'
        'media'
      when 'car browser'
        'car'
      else
        'monitor-o'
      end

    sprite_icon(icon_name, css_class: 'gl-mt-2')
  end

  def revoke_session_path(active_session)
    profile_active_session_path(active_session.session_private_id)
  end
end
