module IconsHelper
  include FontAwesome::Rails::IconHelper

  # Creates an icon tag given icon name(s) and possible icon modifiers.
  #
  # Right now this method simply delegates directly to `fa_icon` from the
  # font-awesome-rails gem, but should we ever use a different icon pack in the
  # future we won't have to change hundreds of method calls.
  def icon(names, options = {})
    fa_icon(names, options)
  end

  def spinner(text = nil, visible = false)
    css_class = 'loading'
    css_class << ' hide' unless visible

    content_tag :div, class: css_class do
      icon('spinner spin') + text
    end
  end

  def boolean_to_icon(value)
    if value
      icon('circle', class: 'cgreen')
    else
      icon('power-off', class: 'clgray')
    end
  end

  def public_icon
    icon('globe fw')
  end

  def internal_icon
    icon('shield fw')
  end

  def private_icon
    icon('lock fw')
  end

  def file_type_icon_class(type, mode, name)
    if type == 'folder'
      icon_class = 'folder'
    elsif mode == '120000'
      icon_class = 'share'
    else
      # Guess which icon to choose based on file extension.
      # If you think a file extension is missing, feel free to add it on PR

      case File.extname(name).downcase
      when '.pdf'
        icon_class = 'file-pdf-o'
      when '.jpg', '.jpeg', '.jif', '.jfif',
          '.jp2', '.jpx', '.j2k', '.j2c',
          '.png', '.gif', '.tif', '.tiff',
          '.svg', '.ico', '.bmp'
        icon_class = 'file-image-o'
      when '.zip', '.zipx', '.tar', '.gz', '.bz', '.bzip',
          '.xz', '.rar', '.7z'
        icon_class = 'file-archive-o'
      when '.mp3', '.wma', '.ogg', '.oga', '.wav', '.flac', '.aac'
        icon_class = 'file-audio-o'
      when '.mp4', '.m4p', '.m4v',
          '.mpg', '.mp2', '.mpeg', '.mpe', '.mpv',
          '.mpg', '.mpeg', '.m2v',
          '.avi', '.mkv', '.flv', '.ogv', '.mov',
          '.3gp', '.3g2'
        icon_class = 'file-video-o'
      when '.doc', '.dot', '.docx', '.docm', '.dotx', '.dotm', '.docb'
        icon_class = 'file-word-o'
      when '.xls', '.xlt', '.xlm', '.xlsx', '.xlsm', '.xltx', '.xltm',
          '.xlsb', '.xla', '.xlam', '.xll', '.xlw'
        icon_class = 'file-excel-o'
      when '.ppt', '.pot', '.pps', '.pptx', '.pptm', '.potx', '.potm',
          '.ppam', '.ppsx', '.ppsm', '.sldx', '.sldm'
        icon_class = 'file-powerpoint-o'
      else
        icon_class = 'file-text-o'
      end
    end

    icon_class
  end
end
