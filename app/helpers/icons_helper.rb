# frozen_string_literal: true

require 'json'

module IconsHelper
  extend self
  include FontAwesome::Rails::IconHelper

  DEFAULT_ICON_SIZE = 16

  # Creates an icon tag given icon name(s) and possible icon modifiers.
  #
  # Right now this method simply delegates directly to `fa_icon` from the
  # font-awesome-rails gem, but should we ever use a different icon pack in the
  # future we won't have to change hundreds of method calls.
  # @deprecated use sprite_icon to render a SVG icon
  def icon(names, options = {})
    if (options.keys & %w[aria-hidden aria-label data-hidden]).empty?
      # Add 'aria-hidden' and 'data-hidden' if they are not set in options.
      options['aria-hidden'] = true
      options['data-hidden'] = true
    end

    options.include?(:base) ? fa_stacked_icon(names, options) : fa_icon(names, options)
  end

  def custom_icon(icon_name, size: DEFAULT_ICON_SIZE)
    memoized_icon("#{icon_name}_#{size}") do
      # We can't simply do the below, because there are some .erb SVGs.
      #  File.read(Rails.root.join("app/views/shared/icons/_#{icon_name}.svg")).html_safe
      render "shared/icons/#{icon_name}.svg", size: size
    end
  end

  def sprite_icon_path
    @sprite_icon_path ||= begin
      # SVG Sprites currently don't work across domains, so in the case of a CDN
      # we have to set the current path deliberately to prevent addition of asset_host
      sprite_base_url = Gitlab.config.gitlab.url if ActionController::Base.asset_host
      ActionController::Base.helpers.image_path('icons.svg', host: sprite_base_url)
    end
  end

  def sprite_file_icons_path
    # SVG Sprites currently don't work across domains, so in the case of a CDN
    # we have to set the current path deliberately to prevent addition of asset_host
    sprite_base_url = Gitlab.config.gitlab.url if ActionController::Base.asset_host
    ActionController::Base.helpers.image_path('file_icons.svg', host: sprite_base_url)
  end

  def sprite_icon(icon_name, size: DEFAULT_ICON_SIZE, css_class: nil)
    memoized_icon("#{icon_name}_#{size}_#{css_class}") do
      if known_sprites&.exclude?(icon_name)
        exception = ArgumentError.new("#{icon_name} is not a known icon in @gitlab-org/gitlab-svg")
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(exception)
      end

      css_classes = []
      css_classes << "s#{size}" if size
      css_classes << "#{css_class}" unless css_class.blank?

      content_tag(
        :svg,
        content_tag(:use, '', { 'xlink:href' => "#{sprite_icon_path}##{icon_name}" } ),
        class: css_classes.empty? ? nil : css_classes.join(' '),
        data: { testid: "#{icon_name}-icon" }
      )
    end
  end

  def loading_icon(container: false, color: 'orange', size: 'sm', css_class: nil)
    css_classes = ['gl-spinner', "gl-spinner-#{color}", "gl-spinner-#{size}"]
    css_classes << "#{css_class}" unless css_class.blank?

    spinner = content_tag(:span, "", { class: css_classes.join(' '), aria: { label: _('Loading') } })

    container == true ? content_tag(:div, spinner, { class: 'gl-spinner-container' }) : spinner
  end

  def external_snippet_icon(name)
    content_tag(:span, "", class: "gl-snippet-icon gl-snippet-icon-#{name}")
  end

  def audit_icon(name, css_class: nil)
    case name
    when "standard"
      name = "key"
    when "two-factor"
      name = "key"
    when "google_oauth2"
      name = "google"
    end

    sprite_icon(name, css_class: css_class)
  end

  def boolean_to_icon(value)
    if value
      sprite_icon('check', css_class: 'cgreen')
    else
      sprite_icon('power', css_class: 'clgray')
    end
  end

  def visibility_level_icon(level, options: {})
    name =
      case level
      when Gitlab::VisibilityLevel::PRIVATE
        'lock'
      when Gitlab::VisibilityLevel::INTERNAL
        'shield'
      else # Gitlab::VisibilityLevel::PUBLIC
        'earth'
      end

    css_class = options.delete(:class)

    sprite_icon(name, size: DEFAULT_ICON_SIZE, css_class: css_class)
  end

  def file_type_icon_class(type, mode, name)
    if type == 'folder'
      icon_class = 'folder-o'
    elsif type == 'archive'
      icon_class = 'archive'
    elsif mode == '120000'
      icon_class = 'share'
    else
      # Guess which icon to choose based on file extension.
      # If you think a file extension is missing, feel free to add it on PR

      case File.extname(name).downcase
      when '.pdf'
        icon_class = 'document'
      when '.jpg', '.jpeg', '.jif', '.jfif',
          '.jp2', '.jpx', '.j2k', '.j2c',
          '.apng', '.png', '.gif', '.tif', '.tiff',
          '.svg', '.ico', '.bmp', '.webp'
        icon_class = 'doc-image'
      when '.zip', '.zipx', '.tar', '.gz', '.gzip', '.tgz', '.bz', '.bzip',
          '.bz2', '.bzip2', '.car', '.tbz', '.xz', 'txz', '.rar', '.7z',
          '.lz', '.lzma', '.tlz'
        icon_class = 'doc-compressed'
      when '.mp3', '.wma', '.ogg', '.oga', '.wav', '.flac', '.aac', '.3ga',
          '.ac3', '.midi', '.m4a', '.ape', '.mpa'
        icon_class = 'volume-up'
      when '.mp4', '.m4p', '.m4v',
          '.mpg', '.mp2', '.mpeg', '.mpe', '.mpv',
          '.mpg', '.mpeg', '.m2v', '.m2ts',
          '.avi', '.mkv', '.flv', '.ogv', '.mov',
          '.3gp', '.3g2'
        icon_class = 'live-preview'
      when '.doc', '.dot', '.docx', '.docm', '.dotx', '.dotm', '.docb',
          '.odt', '.ott', '.uot', '.rtf'
        icon_class = 'doc-text'
      when '.xls', '.xlt', '.xlm', '.xlsx', '.xlsm', '.xltx', '.xltm',
          '.xlsb', '.xla', '.xlam', '.xll', '.xlw', '.ots', '.ods', '.uos'
        icon_class = 'document'
      when '.ppt', '.pot', '.pps', '.pptx', '.pptm', '.potx', '.potm',
          '.ppam', '.ppsx', '.ppsm', '.sldx', '.sldm', '.odp', '.otp', '.uop'
        icon_class = 'doc-chart'
      else
        icon_class = 'doc-text'
      end
    end

    icon_class
  end

  private

  def known_sprites
    return if Rails.env.production?

    @known_sprites ||= Gitlab::Json.parse(File.read(Rails.root.join('node_modules/@gitlab/svgs/dist/icons.json')))['icons']
  end

  def memoized_icon(key)
    @rendered_icons ||= {}

    @rendered_icons[key] || (
      @rendered_icons[key] = yield
    )
  end
end
