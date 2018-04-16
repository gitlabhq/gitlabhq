module IconsHelper
  extend self
  include FontAwesome::Rails::IconHelper

  # Creates an icon tag given icon name(s) and possible icon modifiers.
  #
  # Right now this method simply delegates directly to `fa_icon` from the
  # font-awesome-rails gem, but should we ever use a different icon pack in the
  # future we won't have to change hundreds of method calls.
  def icon(names, options = {})
    if (options.keys & %w[aria-hidden aria-label data-hidden]).empty?
      # Add 'aria-hidden' and 'data-hidden' if they are not set in options.
      options['aria-hidden'] = true
      options['data-hidden'] = true
    end

    options.include?(:base) ? fa_stacked_icon(names, options) : fa_icon(names, options)
  end

  def custom_icon(icon_name, size: 16)
    # We can't simply do the below, because there are some .erb SVGs.
    #  File.read(Rails.root.join("app/views/shared/icons/_#{icon_name}.svg")).html_safe
    render "shared/icons/#{icon_name}.svg", size: size
  end

  def sprite_icon_path
    # SVG Sprites currently don't work across domains, so in the case of a CDN
    # we have to set the current path deliberately to prevent addition of asset_host
    sprite_base_url = Gitlab.config.gitlab.url if ActionController::Base.asset_host
    ActionController::Base.helpers.image_path('icons.svg', host: sprite_base_url)
  end

  def sprite_file_icons_path
    # SVG Sprites currently don't work across domains, so in the case of a CDN
    # we have to set the current path deliberately to prevent addition of asset_host
    sprite_base_url = Gitlab.config.gitlab.url if ActionController::Base.asset_host
    ActionController::Base.helpers.image_path('file_icons.svg', host: sprite_base_url)
  end

  def sprite_icon(icon_name, size: nil, css_class: nil)
    css_classes = size ? "s#{size}" : ""
    css_classes << " #{css_class}" unless css_class.blank?
    content_tag(:svg, content_tag(:use, "", { "xlink:href" => "#{sprite_icon_path}##{icon_name}" } ), class: css_classes.empty? ? nil : css_classes)
  end

  def external_snippet_icon(name)
    content_tag(:span, "", class: "gl-snippet-icon gl-snippet-icon-#{name}")
  end

  def audit_icon(names, options = {})
    case names
    when "standard"
      names = "key"
    when "two-factor"
      names = "key"
    end

    options.include?(:base) ? fa_stacked_icon(names, options) : fa_icon(names, options)
  end

  def spinner(text = nil, visible = false)
    css_class = 'loading'
    css_class << ' hidden' unless visible

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

  def visibility_level_icon(level, fw: true)
    name =
      case level
      when Gitlab::VisibilityLevel::PRIVATE
        'lock'
      when Gitlab::VisibilityLevel::INTERNAL
        'shield'
      else # Gitlab::VisibilityLevel::PUBLIC
        'globe'
      end

    name << " fw" if fw

    icon(name)
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
